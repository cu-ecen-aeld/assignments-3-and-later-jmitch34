
CROSS_COMPILE ?=

CC:= $(CROSS_COMPILE)gcc

SRC := writer.c
TARGET := writer

default: $(TARGET)

$(TARGET): $(SRC)
	$(CC) -o $@ $^

clean:
	rm -f $(TARGET) *.o
