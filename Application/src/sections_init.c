#include <stdint.h>

// The type of a pointer into the init table.
typedef void const * table_ptr_t;

// The type of an initialization routine. It takes a pointer to the start of
// its entry (after the function pointer) in the init table and returns a
// pointer to after its entry.
typedef table_ptr_t init_fun_t( table_ptr_t );

typedef struct
{
  int32_t mOff;
} FAddr;

__no_init uint32_t __iar_SB @ r9;

uint32_t const * __iar_zero_init3( uint32_t const * p )
{
  uint32_t size;
  while ( ( size = *p++ ) != 0 )
  {
    uint32_t d = *p++;
    uint32_t * dest;

    if ( d & 1 )
    {
      d -= 1;
      d += __iar_SB;
    }

    dest = (uint32_t*) d;

    do
    {
      *dest++ = 0;
      size -= 4;
    }while ( size != 0 );
  }
  return p;
}

uint32_t const * __iar_copy_init3( uint32_t const * p )
{
  uint32_t size;
  while ( ( size = *p++ ) != 0 )
  {
    uint32_t const * src;
    uint32_t d;
    uint32_t * dest;

    src = (uint32_t *) ( (char const *) p + *(int32_t *) p );
    p++;

    d = *p++;

    if ( d & 1 )
    {
      d -= 1;
      d += __iar_SB;
    }

    dest = (uint32_t *) d;

    do
    {
      *dest++ = *src++;
      size -= 4;
    }while ( size != 0 );
  }
  return p;
}

#pragma section = "Region$$Table"
void __iar_data_init3( void )
{
  FAddr const * pi = __section_begin("Region$$Table");
  table_ptr_t pe = __section_end ("Region$$Table");
  while ( pi != pe )
  {
    init_fun_t * fun = (init_fun_t *) ( (uint32_t) pi + pi->mOff );
    ++pi;
    pi = fun( pi );
  }
}