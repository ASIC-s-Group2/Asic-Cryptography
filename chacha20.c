//only tested for one block (no streams)

#include <stdio.h>
#include <string.h>
#include <time.h>
#include <stdint.h>
#include <stdlib.h>

const char constant[] = "expand 32-byte k";
const char plainText[] = "i <3 eating silicon crystals and chacha20ing all over the place!";
const char *key_string = "onlythirthytwocharactersfor2xcha";
const char *nonce_string = "123456789012";

void setToRandomBytes(unsigned char *buffer, size_t len) {
	for (size_t i = 0; i < len; i++) {
		buffer[i] = rand() % 256;
	}
}

void printHex(const unsigned char *data, size_t length) {
    for (size_t i = 0; i < length; i++) {
        printf("%02X", data[i]);
    }
    printf("\n");
}

uint32_t bytes_to_u32_le(const unsigned char *bytes) {
    return (uint32_t)bytes[0] | 
           ((uint32_t)bytes[1] << 8) | 
           ((uint32_t)bytes[2] << 16) | 
           ((uint32_t)bytes[3] << 24);
}

void u32_to_bytes_le(uint32_t value, unsigned char *bytes) {
    bytes[0] = value & 0xff;
    bytes[1] = (value >> 8) & 0xff;
    bytes[2] = (value >> 16) & 0xff;
    bytes[3] = (value >> 24) & 0xff;
}

void rotL(uint32_t *x, int n) {
	*x = (*x << n) | (*x >> (32 - n));
}

void qr(uint32_t *a, uint32_t *b, uint32_t *c, uint32_t *d) {
	*a += *b; *d ^= *a; rotL(d, 16);
	*c += *d; *b ^= *c; rotL(b, 12);
	*a += *b; *d ^= *a; rotL(d, 8);
	*c += *d; *b ^= *c; rotL(b, 7);
}

void chacha20_block(const unsigned char *key, uint32_t counter, const unsigned char *nonce, unsigned char *keystream) {
	uint32_t blocks[16];
	
	blocks[0] = 0x61707865;  // expa
	blocks[1] = 0x3320646e;  // nd 3
	blocks[2] = 0x79622d32;  // 2-by
	blocks[3] = 0x6b206574;  // te k
	for (int i = 0; i < 8; i++) {
		blocks[4 + i] = bytes_to_u32_le(key + i * 4);
	}
	blocks[12] = counter;
	for (int i = 0; i < 3; i++) {
		blocks[13 + i] = bytes_to_u32_le(nonce + i * 4);
	}

	uint32_t orig[16];
	for (int i = 0; i < 16; i++) {
		orig[i] = blocks[i];
	}
	
	for (int i = 0; i < 10; i++) {
		//column
		qr(&blocks[0], &blocks[4], &blocks[8], &blocks[12]);
		qr(&blocks[1], &blocks[5], &blocks[9], &blocks[13]);
		qr(&blocks[2], &blocks[6], &blocks[10], &blocks[14]);
		qr(&blocks[3], &blocks[7], &blocks[11], &blocks[15]);
		//diagonal
		qr(&blocks[0], &blocks[5], &blocks[10], &blocks[15]);
		qr(&blocks[1], &blocks[6], &blocks[11], &blocks[12]);
		qr(&blocks[2], &blocks[7], &blocks[8], &blocks[13]);
		qr(&blocks[3], &blocks[4], &blocks[9], &blocks[14]);
	}

	for (int i = 0; i < 16; i++) {
		blocks[i]+=orig[i];
	}

	for (int i = 0; i<16; i++) {
		u32_to_bytes_le(blocks[i], keystream+i*4);
	}
}

int main() {
	srand(time(NULL));
	size_t constantBits = (sizeof(constant) - 1) * 8;
	size_t plainTextBits = (sizeof(plainText) - 1) * 8;
	if (constantBits != 128 || plainTextBits != 512) {
		printf("error: constant or plainText not correct size\n");
		return 1;
	}

	uint32_t counter = 1;
	unsigned char key[32];
	unsigned char nonce[12];
	unsigned char keystream[64];
	// setToRandomBytes(key, sizeof(key));
	// setToRandomBytes(nonce, sizeof(nonce));
    memcpy(key, key_string, 32);
    memcpy(nonce, nonce_string, 12);

    //printHex(key, 32);
    //printHex(nonce, 12);

	chacha20_block(key, counter, nonce, keystream);

	unsigned char cipherText[64];
	for (int i = 0; i<64; i++) {
		cipherText[i] = plainText[i] ^ keystream[i];
	}

    printHex(cipherText, 64);

	return 0;
}
