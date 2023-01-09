/* source: dalan.c */
/* Copyright Gerhard Rieger and contributors (see file CHANGES) */
/* Published under the GNU General Public License V.2, see file COPYING */

/* idea of a low level data description language. currently only a most
   primitive subset exists. */

#include "config.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#if HAVE_STDBOOL_H
#include <stdbool.h>
#endif
#include <ctype.h>
#include "dalan.h"

/* test structure to find maximal alignment */
static struct {
  char a;
  long double b;
} maxalign;

/* test structure to find minimal alignment */
static struct {
  char a;
  char b;
} minalign;

/* test union to find kind of byte ordering */
static union {
  char a[2];
  short b;
} byteorder = { "01" };

struct dalan_opts_s dalan_opts = {
  sizeof(int),
  sizeof(short),
  sizeof(long),
  sizeof(char),
  sizeof(float),
  sizeof(double)
} ;

/* fill the dalan_opts structure with machine dependent defaults values. */
static void _dalan_dflts(struct dalan_opts_s *dlo) {
  dlo->c_int = sizeof(int);
  dlo->c_short = sizeof(short);
  dlo->c_long = sizeof(long);
  dlo->c_char = sizeof(char);
  dlo->c_float = sizeof(float);
  dlo->c_double = sizeof(double);
  dlo->maxalign = (char *)&maxalign.b-&maxalign.a;
  dlo->minalign = &minalign.b-&minalign.a;
  dlo->byteorder = (byteorder.b!=7711);
}

/* allocate a new dalan_opts structure, fills it with machine dependent
   defaults values, and returns the pointer. */
struct dalan_opts_s *dalan_props(void) {
  struct dalan_opts_s *dlo;
  dlo = malloc(sizeof(struct dalan_opts_s));
  if (dlo == NULL) {
    return NULL;
  }
  _dalan_dflts(dlo);
  return dlo;
}

void dalan_init(void) {
  _dalan_dflts(&dalan_opts);
}

/* Parses and coverts a data item.
   Returns 0 on success,
   -1 if the data was cut due to n limit,
   1 if a syntax error occurred
   2 if the actual character is white space
   3 if the first character is not a type specifier
*/
static int dalan_item(int c, const char **line0, uint8_t *data, size_t *p, size_t n) {
   const char *line = *line0;
   size_t p1 = *p;

   switch (c) {
   case ' ':
   case '\t':
   case '\r':
   case '\n':
      return 2;
   case '"':
      while (1) {
	 switch (c = *line++) {
	 case '\0': fputs("unterminated string\n", stderr);
	    *line0 = line;
	    return 1;
	 case '"':
	    break;
	 case '\\':
	    if (!(c = *line++)) {
	       fputs("continuation line not implemented\n", stderr);
	       *line0 = line;
	       return 1;
	    }
	    switch (c) {
	    case 'n': c = '\n'; break;
	    case 'r': c = '\r'; break;
	    case 't': c = '\t'; break;
	    case 'f': c = '\f'; break;
	    case 'b': c = '\b'; break;
	    case 'a': c = '\a'; break;
#if 0
	    case 'e': c = '\e'; break;
#else
	    case 'e': c = '\033'; break;
#endif
	    case '0': c = '\0'; break;
	    }
	    /* PASSTHROUGH */
	 default:
	    if (p1 >= n) {
	       *p = p1;
	       *line0 = line;
	       return -1;
	    }
	    data[p1++] = c;
	    continue;
	 }
	 if (c == '"')
	    break;
      }
      break;
   case '\'':
      switch (c = *line++) {
      case '\0': fputs("unterminated character\n", stderr);
	 *line0 = line;
	 return 1;
      case '\'': fputs("error in character\n", stderr);
	 *line0 = line;
	 return 1;
      case '\\':
	 if (!(c = *line++)) {
	    fputs("continuation line not implemented\n", stderr);
	    *line0 = line;
	    return 1;
	 }
	 switch (c) {
	 case 'n': c = '\n'; break;
	 case 'r': c = '\r'; break;
	 case 't': c = '\t'; break;
	 case 'f': c = '\f'; break;
	 case 'b': c = '\b'; break;
	 case 'a': c = '\a'; break;
#if 0
	 case 'e': c = '\e'; break;
#else
	 case 'e': c = '\033'; break;
#endif
	 }
	 /* PASSTHROUGH */
      default:
	 if (p1 >= n) { *p = p1; return -1; }
	 data[p1++] = c;
	 break;
      }
      if (*line != '\'') {
	 fputs("error in character termination\n", stderr);
	 *p = p1;
	 *line0 = line;
	 return 1;
      }
      ++line;
      break;
   case 'x':
      /* expecting hex data, must be an even number of digits!! */
      while (true) {
	 int x;
	 c = *line;
	 if (isdigit(c&0xff)) {
	    x = (c-'0') << 4;
	 } else if (isxdigit(c&0xff)) {
	    x = ((c&0x07) + 9) << 4;
	 } else
	    break;
	 ++line;
	 c = *line;
	 if (isdigit(c&0xff)) {
	    x |= (c-'0');
	 } else if (isxdigit(c&0xff)) {
	    x |= (c&0x07) + 9;
	 } else {
	    fputs("odd number of hexadecimal digits\n", stderr);
	    *p = p1;
	    *line0 = line;
	    return 1;
	 }
	 ++line;
	 if (p1 >= n) {
	    *p = p1;
	    *line0 = line;
	    return -1;
	 }
	 data[p1++] = x;
      }
      break;
   case 'l':
      /* expecting decimal number, with target type long */
      {
	 char *endptr;
	 *(long *)&data[p1] = strtol(line, &endptr, 10);
	 p1 += sizeof(long);
	 line = endptr;
      }
      break;
   case 'L':
      /* expecting decimal number, with target type unsigned long */
      {
	 char *endptr;
	 *(unsigned long *)&data[p1] = strtol(line, &endptr, 10);
	 p1 += sizeof(unsigned long);
	 line = endptr;
      }
      break;
   case 'i':
      /* expecting decimal number, with target type int */
      {
	 char *endptr;
	 *(int *)&data[p1] = strtol(line, &endptr, 10);
	 p1 += sizeof(int);
	 line = endptr;
      }
      break;
   case 'I':
      /* expecting decimal number, with target type unsigned int */
      {
	 char *endptr;
	 *(unsigned int *)&data[p1] = strtol(line, &endptr, 10);
	 p1 += sizeof(unsigned int);
	 line = endptr;
      }
      break;
   case 's':
      /* expecting decimal number, with target type short */
      {
	 char *endptr;
	 *(short *)&data[p1] = strtol(line, &endptr, 10);
	 p1 += sizeof(short);
	 line = endptr;
      }
      break;
   case 'S':
      /* expecting decimal number, with target type unsigned short */
      {
	 char *endptr;
	 *(unsigned short *)&data[p1] = strtol(line, &endptr, 10);
	 p1 += sizeof(unsigned short);
	 line = endptr;
      }
      break;
   case 'b':
      /* expecting decimal number, with target type byte (int8_t) */
      {
	 char *endptr;
	 *(int8_t *)&data[p1] = strtoul(line, &endptr, 10);
	 p1 += sizeof(uint8_t);
	 line = endptr;
      }
   case 'B':
      /* expecting decimal number, with target type byte (uint8_t) */
      {
	 char *endptr;
	 *(uint8_t *)&data[p1] = strtoul(line, &endptr, 10);
	 p1 += sizeof(uint8_t);
	 line = endptr;
      }
      break;
   default:
      *line0 = line;
      return 3;
   }
   *p = p1;
   *line0 = line;
   return 0;
}

/* read data description from line (\0-terminated), write result to data; do
   not write so much data that *p exceeds n !
   p must be initialized to 0.
   return 0 on success,
   -1 if the data was cut due to n limit,
   1 if a syntax error occurred
   *p is a global data counter; especially it must be used when calculating
     alignment. On successful return from the function *p must be actual!
*/
int dalan(const char *line, uint8_t *data, size_t *p, size_t n, char deflt) {
   size_t p0;
   char c;
   int rc;

   while (1) {
      /* assume there is a type specifier on beginning of rest of line */
      c = *line++;
      if (c == '\0')
	 break;
      p0 = *p;
      rc = dalan_item(c, &line, data, p, n);
      if (rc == 0) {
	 deflt = c; 	/* continue with this type as default */
      } else if (rc == 2) {
	 /* white space */
	 continue;
      } else if (rc == 3) {
	 /* no, we did not recognize c as type specifier, try default type */
	 --line;
	 rc = dalan_item(deflt, &line, data, p, n);
      }
      if (rc != 0) {
	 return rc;
      }
      /* rc == 0 */
      n -= (*p-p0);
   }
   return 0;
}
