file.

# Define the application's title and name
APP_TITLE = Flappy NumWorks
APP_NAME = flappy

# List all source files for your application
APP_SOURCES = main.c

# Include the main NumWorks SDK Makefile
# This line pulls in all the necessary build rules, toolchain definitions, etc.
include $(ION_SDK_PATH)/Ion/N0110/Makefile
