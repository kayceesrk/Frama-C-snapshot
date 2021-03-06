#include <string.h>

void test_strcmp(void)
{
  int res = strcmp("hello", "world");
  //@ assert res == 0;
}

void test_strcat(void)
{
  char string[10];
  string[0] = 0;
  strcat(string, "hello");
}

volatile int nondet;
void test_strstr(void)
{
  char *s = nondet ? "aba" : "bab";
  char *needle = nondet ? "a" : "b";
  char *res = strstr(s, needle);
  //@ assert res != 0;
}

int main(int argc, char **argv)
{
  test_strcmp();
  test_strcat();
  test_strstr();
  return 0;
}
