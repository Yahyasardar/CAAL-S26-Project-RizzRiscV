CC = riscv-none-elf-gcc
CFLAGS = -march=rv64gcv -mabi=lp64d -nostdlib -static

QEMU = qemu-riscv64
QEMU_FLAGS = -cpu rv64,v=true,vlen=128,elen=64

TARGET = nbody_vec.elf
SRC = nbody_vec.S

all: $(TARGET)

$(TARGET): $(SRC) mydata.S
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC)

run: $(TARGET)
	$(QEMU) $(QEMU_FLAGS) ./$(TARGET)

profile: $(TARGET)
	$(QEMU) $(QEMU_FLAGS) -plugin ~/Downloads/libinsn_profile_v2.so -d plugin ./$(TARGET)

clean:
	rm -f $(TARGET) shared.mem
