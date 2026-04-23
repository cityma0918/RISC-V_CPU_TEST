OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS
{
    . = ORIGIN(RAM);

    .text : {
        *(.text.init)
        *(.text*)
        *(.rodata*)
    } > RAM

    . = ALIGN(4);
    .data : {
        *(.data*)
    } > RAM

    . = ALIGN(4);
    .bss : {
        *(.bss*)
        *(COMMON)
    } > RAM

    .signature 0x00001000 : {
        __signature = .;
        *(.signature)
    } > RAM

    . = ALIGN(16);
    _end = .;
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
