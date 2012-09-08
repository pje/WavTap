#import <Cocoa/Cocoa.h>

void SignalHandler(int signal)
{
  printf("trapped signal: %i", signal);
}

int main(int argc, const char *argv[])
{
  signal(SIGINT, SignalHandler);
  signal(SIGQUIT, SignalHandler);
  signal(SIGTERM, SignalHandler);
  signal(SIGABRT, SignalHandler);
  signal(SIGILL, SignalHandler);
  signal(SIGSEGV, SignalHandler);
  signal(SIGFPE, SignalHandler);
  signal(SIGBUS, SignalHandler);
  signal(SIGPIPE, SignalHandler);
  return NSApplicationMain(argc, argv);
}
