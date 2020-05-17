#include <stddef.h>

#include <FreeRTOS.h>
#include <task.h>

#include "app_config.h"
#include "print.h"
#include "receive.h"


///* Task function - may be instantiated in multiple tasks */
void vTaskFunction( void *pvParameters )
{
    portCHAR* taskName;
    UBaseType_t  delay;

    taskName = pcTaskGetName(NULL);
    delay = 2000;
    for( ; ; )
    {
        /* Print out the name of this task. */
        vPrintMsg(taskName);
        vTaskDelay( delay / portTICK_RATE_MS );
    }
    vTaskDelete(NULL);
}

void vPeriodicTaskFunction(void* pvParameters)
{
    const portCHAR* taskName;
    UBaseType_t delay;
    
    TickType_t lastWakeTime;

    taskName = "Periodic task\r\n";
    delay = 3000;

    // Get time of last task execution
    lastWakeTime = xTaskGetTickCount();

    for( ; ; )
    {
        /* Print out the name of this task. */
        vPrintMsg(taskName);
        /*
         * The task will unblock exactly after 'delay' milliseconds (actually
         * after the appropriate number of ticks), relative from the moment
         * it was last unblocked.
         */
        vTaskDelayUntil( &lastWakeTime, delay / portTICK_RATE_MS );
    }
    vTaskDelete(NULL);
}

/*
 * A convenience function that is called when a FreeRTOS API call fails
 * and a program cannot continue. It prints a message (if provided) and
 * ends in an infinite loop.
 */
static void FreeRTOS_Error(const portCHAR* msg)
{
    if ( NULL != msg )
    {
        vDirectPrintMsg(msg);
    }

    for ( ; ; );
}

//void vApplicationIdleHook()
//{
//  
//}

/* Startup function that creates and runs two FreeRTOS tasks */
void main(void)
{
    /* Init of print related tasks: */
    if ( pdFAIL == printInit(PRINT_UART_NR) )
    {
        FreeRTOS_Error("Initialization of print failed\r\n");
    }

    vDirectPrintMsg("= = = T E S T   S T A R T E D = = =\r\n\r\n");

    /* Init of receiver related tasks: */
    if ( pdFAIL == recvInit(RECV_UART_NR) )
    {
        FreeRTOS_Error("Initialization of receiver failed\r\n");
    }

    /* Create a print gate keeper task: */
    if ( pdPASS != xTaskCreate(printGateKeeperTask, "gk", 128, NULL,
                               PRIOR_PRINT_GATEKEEPR, NULL) )
    {
        FreeRTOS_Error("Could not create a print gate keeper task\r\n");
    }

    if ( pdPASS != xTaskCreate(recvTask, "recv", 128, NULL, PRIOR_RECEIVER, NULL) )
    {
        FreeRTOS_Error("Could not create a receiver task\r\n");
    }

    /* And finally create two tasks: */
    if ( pdPASS != xTaskCreate(vTaskFunction, "task1\r\n", 128, NULL,
                               PRIOR_PERIODIC, NULL) )
    {
        FreeRTOS_Error("Could not create task1\r\n");
    }

    if ( pdPASS != xTaskCreate(vPeriodicTaskFunction, "task2", 128, NULL,
                               PRIOR_FIX_FREQ_PERIODIC, NULL) )
    {
        FreeRTOS_Error("Could not create task2\r\n");
    }

    vDirectPrintMsg("A text may be entered using a keyboard.\r\n");
    vDirectPrintMsg("It will be displayed when 'Enter' is pressed.\r\n\r\n");

    /* Start the FreeRTOS scheduler */
    vTaskStartScheduler();

    /*
     * If all goes well, vTaskStartScheduler should never return.
     * If it does return, typically not enough heap memory is reserved.
     */

    FreeRTOS_Error("Could not start the scheduler!!!\r\n");

    /* just in case if an infinite loop is somehow omitted in FreeRTOS_Error */
    for ( ; ; );
}
