/*
 * Autogenerated from the following JSON policy
 */

#if 0


 Original JSON size: 13
#endif

static const uint32_t _rbo_bo_0[] = {
 1000,  2000,  3000,  5000,  10000, 
};
static const lws_retry_bo_t _rbo_0 = {
	.retry_ms_table = _rbo_bo_0,
	.retry_ms_table_count = 5,
	.conceal_count = 25,
	.secs_since_valid_ping = 30,
	.secs_since_valid_hangup = 35,
	.jitter_percent = 20,
};
static const uint8_t _ss_der_isrg_root_x1[] = {
	/* 0x  0 */ 0x30, 0x82, 0x05, 0x6B, 0x30, 0x82, 0x03, 0x53, 
	/* 0x  8 */ 0xA0, 0x03, 0x02, 0x01, 0x02, 0x02, 0x11, 0x00, 
	/* 0x 10 */ 0x82, 0x10, 0xCF, 0xB0, 0xD2, 0x40, 0xE3, 0x59, 
	/* 0x 18 */ 0x44, 0x63, 0xE0, 0xBB, 0x63, 0x82, 0x8B, 0x00, 
	/* 0x 20 */ 0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 
	/* 0x 28 */ 0xF7, 0x0D, 0x01, 0x01, 0x0B, 0x05, 0x00, 0x30, 
	/* 0x 30 */ 0x4F, 0x31, 0x0B, 0x30, 0x09, 0x06, 0x03, 0x55, 
	/* 0x 38 */ 0x04, 0x06, 0x13, 0x02, 0x55, 0x53, 0x31, 0x29, 
	/* 0x 40 */ 0x30, 0x27, 0x06, 0x03, 0x55, 0x04, 0x0A, 0x13, 
	/* 0x 48 */ 0x20, 0x49, 0x6E, 0x74, 0x65, 0x72, 0x6E, 0x65, 
	/* 0x 50 */ 0x74, 0x20, 0x53, 0x65, 0x63, 0x75, 0x72, 0x69, 
	/* 0x 58 */ 0x74, 0x79, 0x20, 0x52, 0x65, 0x73, 0x65, 0x61, 
	/* 0x 60 */ 0x72, 0x63, 0x68, 0x20, 0x47, 0x72, 0x6F, 0x75, 
	/* 0x 68 */ 0x70, 0x31, 0x15, 0x30, 0x13, 0x06, 0x03, 0x55, 
	/* 0x 70 */ 0x04, 0x03, 0x13, 0x0C, 0x49, 0x53, 0x52, 0x47, 
	/* 0x 78 */ 0x20, 0x52, 0x6F, 0x6F, 0x74, 0x20, 0x58, 0x31, 
	/* 0x 80 */ 0x30, 0x1E, 0x17, 0x0D, 0x31, 0x35, 0x30, 0x36, 
	/* 0x 88 */ 0x30, 0x34, 0x31, 0x31, 0x30, 0x34, 0x33, 0x38, 
	/* 0x 90 */ 0x5A, 0x17, 0x0D, 0x33, 0x35, 0x30, 0x36, 0x30, 
	/* 0x 98 */ 0x34, 0x31, 0x31, 0x30, 0x34, 0x33, 0x38, 0x5A, 
	/* 0x a0 */ 0x30, 0x4F, 0x31, 0x0B, 0x30, 0x09, 0x06, 0x03, 
	/* 0x a8 */ 0x55, 0x04, 0x06, 0x13, 0x02, 0x55, 0x53, 0x31, 
	/* 0x b0 */ 0x29, 0x30, 0x27, 0x06, 0x03, 0x55, 0x04, 0x0A, 
	/* 0x b8 */ 0x13, 0x20, 0x49, 0x6E, 0x74, 0x65, 0x72, 0x6E, 
	/* 0x c0 */ 0x65, 0x74, 0x20, 0x53, 0x65, 0x63, 0x75, 0x72, 
	/* 0x c8 */ 0x69, 0x74, 0x79, 0x20, 0x52, 0x65, 0x73, 0x65, 
	/* 0x d0 */ 0x61, 0x72, 0x63, 0x68, 0x20, 0x47, 0x72, 0x6F, 
	/* 0x d8 */ 0x75, 0x70, 0x31, 0x15, 0x30, 0x13, 0x06, 0x03, 
	/* 0x e0 */ 0x55, 0x04, 0x03, 0x13, 0x0C, 0x49, 0x53, 0x52, 
	/* 0x e8 */ 0x47, 0x20, 0x52, 0x6F, 0x6F, 0x74, 0x20, 0x58, 
	/* 0x f0 */ 0x31, 0x30, 0x82, 0x02, 0x22, 0x30, 0x0D, 0x06, 
	/* 0x f8 */ 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 
	/* 0x100 */ 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x02, 0x0F, 
	/* 0x108 */ 0x00, 0x30, 0x82, 0x02, 0x0A, 0x02, 0x82, 0x02, 
	/* 0x110 */ 0x01, 0x00, 0xAD, 0xE8, 0x24, 0x73, 0xF4, 0x14, 
	/* 0x118 */ 0x37, 0xF3, 0x9B, 0x9E, 0x2B, 0x57, 0x28, 0x1C, 
	/* 0x120 */ 0x87, 0xBE, 0xDC, 0xB7, 0xDF, 0x38, 0x90, 0x8C, 
	/* 0x128 */ 0x6E, 0x3C, 0xE6, 0x57, 0xA0, 0x78, 0xF7, 0x75, 
	/* 0x130 */ 0xC2, 0xA2, 0xFE, 0xF5, 0x6A, 0x6E, 0xF6, 0x00, 
	/* 0x138 */ 0x4F, 0x28, 0xDB, 0xDE, 0x68, 0x86, 0x6C, 0x44, 
	/* 0x140 */ 0x93, 0xB6, 0xB1, 0x63, 0xFD, 0x14, 0x12, 0x6B, 
	/* 0x148 */ 0xBF, 0x1F, 0xD2, 0xEA, 0x31, 0x9B, 0x21, 0x7E, 
	/* 0x150 */ 0xD1, 0x33, 0x3C, 0xBA, 0x48, 0xF5, 0xDD, 0x79, 
	/* 0x158 */ 0xDF, 0xB3, 0xB8, 0xFF, 0x12, 0xF1, 0x21, 0x9A, 
	/* 0x160 */ 0x4B, 0xC1, 0x8A, 0x86, 0x71, 0x69, 0x4A, 0x66, 
	/* 0x168 */ 0x66, 0x6C, 0x8F, 0x7E, 0x3C, 0x70, 0xBF, 0xAD, 
	/* 0x170 */ 0x29, 0x22, 0x06, 0xF3, 0xE4, 0xC0, 0xE6, 0x80, 
	/* 0x178 */ 0xAE, 0xE2, 0x4B, 0x8F, 0xB7, 0x99, 0x7E, 0x94, 
	/* 0x180 */ 0x03, 0x9F, 0xD3, 0x47, 0x97, 0x7C, 0x99, 0x48, 
	/* 0x188 */ 0x23, 0x53, 0xE8, 0x38, 0xAE, 0x4F, 0x0A, 0x6F, 
	/* 0x190 */ 0x83, 0x2E, 0xD1, 0x49, 0x57, 0x8C, 0x80, 0x74, 
	/* 0x198 */ 0xB6, 0xDA, 0x2F, 0xD0, 0x38, 0x8D, 0x7B, 0x03, 
	/* 0x1a0 */ 0x70, 0x21, 0x1B, 0x75, 0xF2, 0x30, 0x3C, 0xFA, 
	/* 0x1a8 */ 0x8F, 0xAE, 0xDD, 0xDA, 0x63, 0xAB, 0xEB, 0x16, 
	/* 0x1b0 */ 0x4F, 0xC2, 0x8E, 0x11, 0x4B, 0x7E, 0xCF, 0x0B, 
	/* 0x1b8 */ 0xE8, 0xFF, 0xB5, 0x77, 0x2E, 0xF4, 0xB2, 0x7B, 
	/* 0x1c0 */ 0x4A, 0xE0, 0x4C, 0x12, 0x25, 0x0C, 0x70, 0x8D, 
	/* 0x1c8 */ 0x03, 0x29, 0xA0, 0xE1, 0x53, 0x24, 0xEC, 0x13, 
	/* 0x1d0 */ 0xD9, 0xEE, 0x19, 0xBF, 0x10, 0xB3, 0x4A, 0x8C, 
	/* 0x1d8 */ 0x3F, 0x89, 0xA3, 0x61, 0x51, 0xDE, 0xAC, 0x87, 
	/* 0x1e0 */ 0x07, 0x94, 0xF4, 0x63, 0x71, 0xEC, 0x2E, 0xE2, 
	/* 0x1e8 */ 0x6F, 0x5B, 0x98, 0x81, 0xE1, 0x89, 0x5C, 0x34, 
	/* 0x1f0 */ 0x79, 0x6C, 0x76, 0xEF, 0x3B, 0x90, 0x62, 0x79, 
	/* 0x1f8 */ 0xE6, 0xDB, 0xA4, 0x9A, 0x2F, 0x26, 0xC5, 0xD0, 
	/* 0x200 */ 0x10, 0xE1, 0x0E, 0xDE, 0xD9, 0x10, 0x8E, 0x16, 
	/* 0x208 */ 0xFB, 0xB7, 0xF7, 0xA8, 0xF7, 0xC7, 0xE5, 0x02, 
	/* 0x210 */ 0x07, 0x98, 0x8F, 0x36, 0x08, 0x95, 0xE7, 0xE2, 
	/* 0x218 */ 0x37, 0x96, 0x0D, 0x36, 0x75, 0x9E, 0xFB, 0x0E, 
	/* 0x220 */ 0x72, 0xB1, 0x1D, 0x9B, 0xBC, 0x03, 0xF9, 0x49, 
	/* 0x228 */ 0x05, 0xD8, 0x81, 0xDD, 0x05, 0xB4, 0x2A, 0xD6, 
	/* 0x230 */ 0x41, 0xE9, 0xAC, 0x01, 0x76, 0x95, 0x0A, 0x0F, 
	/* 0x238 */ 0xD8, 0xDF, 0xD5, 0xBD, 0x12, 0x1F, 0x35, 0x2F, 
	/* 0x240 */ 0x28, 0x17, 0x6C, 0xD2, 0x98, 0xC1, 0xA8, 0x09, 
	/* 0x248 */ 0x64, 0x77, 0x6E, 0x47, 0x37, 0xBA, 0xCE, 0xAC, 
	/* 0x250 */ 0x59, 0x5E, 0x68, 0x9D, 0x7F, 0x72, 0xD6, 0x89, 
	/* 0x258 */ 0xC5, 0x06, 0x41, 0x29, 0x3E, 0x59, 0x3E, 0xDD, 
	/* 0x260 */ 0x26, 0xF5, 0x24, 0xC9, 0x11, 0xA7, 0x5A, 0xA3, 
	/* 0x268 */ 0x4C, 0x40, 0x1F, 0x46, 0xA1, 0x99, 0xB5, 0xA7, 
	/* 0x270 */ 0x3A, 0x51, 0x6E, 0x86, 0x3B, 0x9E, 0x7D, 0x72, 
	/* 0x278 */ 0xA7, 0x12, 0x05, 0x78, 0x59, 0xED, 0x3E, 0x51, 
	/* 0x280 */ 0x78, 0x15, 0x0B, 0x03, 0x8F, 0x8D, 0xD0, 0x2F, 
	/* 0x288 */ 0x05, 0xB2, 0x3E, 0x7B, 0x4A, 0x1C, 0x4B, 0x73, 
	/* 0x290 */ 0x05, 0x12, 0xFC, 0xC6, 0xEA, 0xE0, 0x50, 0x13, 
	/* 0x298 */ 0x7C, 0x43, 0x93, 0x74, 0xB3, 0xCA, 0x74, 0xE7, 
	/* 0x2a0 */ 0x8E, 0x1F, 0x01, 0x08, 0xD0, 0x30, 0xD4, 0x5B, 
	/* 0x2a8 */ 0x71, 0x36, 0xB4, 0x07, 0xBA, 0xC1, 0x30, 0x30, 
	/* 0x2b0 */ 0x5C, 0x48, 0xB7, 0x82, 0x3B, 0x98, 0xA6, 0x7D, 
	/* 0x2b8 */ 0x60, 0x8A, 0xA2, 0xA3, 0x29, 0x82, 0xCC, 0xBA, 
	/* 0x2c0 */ 0xBD, 0x83, 0x04, 0x1B, 0xA2, 0x83, 0x03, 0x41, 
	/* 0x2c8 */ 0xA1, 0xD6, 0x05, 0xF1, 0x1B, 0xC2, 0xB6, 0xF0, 
	/* 0x2d0 */ 0xA8, 0x7C, 0x86, 0x3B, 0x46, 0xA8, 0x48, 0x2A, 
	/* 0x2d8 */ 0x88, 0xDC, 0x76, 0x9A, 0x76, 0xBF, 0x1F, 0x6A, 
	/* 0x2e0 */ 0xA5, 0x3D, 0x19, 0x8F, 0xEB, 0x38, 0xF3, 0x64, 
	/* 0x2e8 */ 0xDE, 0xC8, 0x2B, 0x0D, 0x0A, 0x28, 0xFF, 0xF7, 
	/* 0x2f0 */ 0xDB, 0xE2, 0x15, 0x42, 0xD4, 0x22, 0xD0, 0x27, 
	/* 0x2f8 */ 0x5D, 0xE1, 0x79, 0xFE, 0x18, 0xE7, 0x70, 0x88, 
	/* 0x300 */ 0xAD, 0x4E, 0xE6, 0xD9, 0x8B, 0x3A, 0xC6, 0xDD, 
	/* 0x308 */ 0x27, 0x51, 0x6E, 0xFF, 0xBC, 0x64, 0xF5, 0x33, 
	/* 0x310 */ 0x43, 0x4F, 0x02, 0x03, 0x01, 0x00, 0x01, 0xA3, 
	/* 0x318 */ 0x42, 0x30, 0x40, 0x30, 0x0E, 0x06, 0x03, 0x55, 
	/* 0x320 */ 0x1D, 0x0F, 0x01, 0x01, 0xFF, 0x04, 0x04, 0x03, 
	/* 0x328 */ 0x02, 0x01, 0x06, 0x30, 0x0F, 0x06, 0x03, 0x55, 
	/* 0x330 */ 0x1D, 0x13, 0x01, 0x01, 0xFF, 0x04, 0x05, 0x30, 
	/* 0x338 */ 0x03, 0x01, 0x01, 0xFF, 0x30, 0x1D, 0x06, 0x03, 
	/* 0x340 */ 0x55, 0x1D, 0x0E, 0x04, 0x16, 0x04, 0x14, 0x79, 
	/* 0x348 */ 0xB4, 0x59, 0xE6, 0x7B, 0xB6, 0xE5, 0xE4, 0x01, 
	/* 0x350 */ 0x73, 0x80, 0x08, 0x88, 0xC8, 0x1A, 0x58, 0xF6, 
	/* 0x358 */ 0xE9, 0x9B, 0x6E, 0x30, 0x0D, 0x06, 0x09, 0x2A, 
	/* 0x360 */ 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0B, 
	/* 0x368 */ 0x05, 0x00, 0x03, 0x82, 0x02, 0x01, 0x00, 0x55, 
	/* 0x370 */ 0x1F, 0x58, 0xA9, 0xBC, 0xB2, 0xA8, 0x50, 0xD0, 
	/* 0x378 */ 0x0C, 0xB1, 0xD8, 0x1A, 0x69, 0x20, 0x27, 0x29, 
	/* 0x380 */ 0x08, 0xAC, 0x61, 0x75, 0x5C, 0x8A, 0x6E, 0xF8, 
	/* 0x388 */ 0x82, 0xE5, 0x69, 0x2F, 0xD5, 0xF6, 0x56, 0x4B, 
	/* 0x390 */ 0xB9, 0xB8, 0x73, 0x10, 0x59, 0xD3, 0x21, 0x97, 
	/* 0x398 */ 0x7E, 0xE7, 0x4C, 0x71, 0xFB, 0xB2, 0xD2, 0x60, 
	/* 0x3a0 */ 0xAD, 0x39, 0xA8, 0x0B, 0xEA, 0x17, 0x21, 0x56, 
	/* 0x3a8 */ 0x85, 0xF1, 0x50, 0x0E, 0x59, 0xEB, 0xCE, 0xE0, 
	/* 0x3b0 */ 0x59, 0xE9, 0xBA, 0xC9, 0x15, 0xEF, 0x86, 0x9D, 
	/* 0x3b8 */ 0x8F, 0x84, 0x80, 0xF6, 0xE4, 0xE9, 0x91, 0x90, 
	/* 0x3c0 */ 0xDC, 0x17, 0x9B, 0x62, 0x1B, 0x45, 0xF0, 0x66, 
	/* 0x3c8 */ 0x95, 0xD2, 0x7C, 0x6F, 0xC2, 0xEA, 0x3B, 0xEF, 
	/* 0x3d0 */ 0x1F, 0xCF, 0xCB, 0xD6, 0xAE, 0x27, 0xF1, 0xA9, 
	/* 0x3d8 */ 0xB0, 0xC8, 0xAE, 0xFD, 0x7D, 0x7E, 0x9A, 0xFA, 
	/* 0x3e0 */ 0x22, 0x04, 0xEB, 0xFF, 0xD9, 0x7F, 0xEA, 0x91, 
	/* 0x3e8 */ 0x2B, 0x22, 0xB1, 0x17, 0x0E, 0x8F, 0xF2, 0x8A, 
	/* 0x3f0 */ 0x34, 0x5B, 0x58, 0xD8, 0xFC, 0x01, 0xC9, 0x54, 
	/* 0x3f8 */ 0xB9, 0xB8, 0x26, 0xCC, 0x8A, 0x88, 0x33, 0x89, 
	/* 0x400 */ 0x4C, 0x2D, 0x84, 0x3C, 0x82, 0xDF, 0xEE, 0x96, 
	/* 0x408 */ 0x57, 0x05, 0xBA, 0x2C, 0xBB, 0xF7, 0xC4, 0xB7, 
	/* 0x410 */ 0xC7, 0x4E, 0x3B, 0x82, 0xBE, 0x31, 0xC8, 0x22, 
	/* 0x418 */ 0x73, 0x73, 0x92, 0xD1, 0xC2, 0x80, 0xA4, 0x39, 
	/* 0x420 */ 0x39, 0x10, 0x33, 0x23, 0x82, 0x4C, 0x3C, 0x9F, 
	/* 0x428 */ 0x86, 0xB2, 0x55, 0x98, 0x1D, 0xBE, 0x29, 0x86, 
	/* 0x430 */ 0x8C, 0x22, 0x9B, 0x9E, 0xE2, 0x6B, 0x3B, 0x57, 
	/* 0x438 */ 0x3A, 0x82, 0x70, 0x4D, 0xDC, 0x09, 0xC7, 0x89, 
	/* 0x440 */ 0xCB, 0x0A, 0x07, 0x4D, 0x6C, 0xE8, 0x5D, 0x8E, 
	/* 0x448 */ 0xC9, 0xEF, 0xCE, 0xAB, 0xC7, 0xBB, 0xB5, 0x2B, 
	/* 0x450 */ 0x4E, 0x45, 0xD6, 0x4A, 0xD0, 0x26, 0xCC, 0xE5, 
	/* 0x458 */ 0x72, 0xCA, 0x08, 0x6A, 0xA5, 0x95, 0xE3, 0x15, 
	/* 0x460 */ 0xA1, 0xF7, 0xA4, 0xED, 0xC9, 0x2C, 0x5F, 0xA5, 
	/* 0x468 */ 0xFB, 0xFF, 0xAC, 0x28, 0x02, 0x2E, 0xBE, 0xD7, 
	/* 0x470 */ 0x7B, 0xBB, 0xE3, 0x71, 0x7B, 0x90, 0x16, 0xD3, 
	/* 0x478 */ 0x07, 0x5E, 0x46, 0x53, 0x7C, 0x37, 0x07, 0x42, 
	/* 0x480 */ 0x8C, 0xD3, 0xC4, 0x96, 0x9C, 0xD5, 0x99, 0xB5, 
	/* 0x488 */ 0x2A, 0xE0, 0x95, 0x1A, 0x80, 0x48, 0xAE, 0x4C, 
	/* 0x490 */ 0x39, 0x07, 0xCE, 0xCC, 0x47, 0xA4, 0x52, 0x95, 
	/* 0x498 */ 0x2B, 0xBA, 0xB8, 0xFB, 0xAD, 0xD2, 0x33, 0x53, 
	/* 0x4a0 */ 0x7D, 0xE5, 0x1D, 0x4D, 0x6D, 0xD5, 0xA1, 0xB1, 
	/* 0x4a8 */ 0xC7, 0x42, 0x6F, 0xE6, 0x40, 0x27, 0x35, 0x5C, 
	/* 0x4b0 */ 0xA3, 0x28, 0xB7, 0x07, 0x8D, 0xE7, 0x8D, 0x33, 
	/* 0x4b8 */ 0x90, 0xE7, 0x23, 0x9F, 0xFB, 0x50, 0x9C, 0x79, 
	/* 0x4c0 */ 0x6C, 0x46, 0xD5, 0xB4, 0x15, 0xB3, 0x96, 0x6E, 
	/* 0x4c8 */ 0x7E, 0x9B, 0x0C, 0x96, 0x3A, 0xB8, 0x52, 0x2D, 
	/* 0x4d0 */ 0x3F, 0xD6, 0x5B, 0xE1, 0xFB, 0x08, 0xC2, 0x84, 
	/* 0x4d8 */ 0xFE, 0x24, 0xA8, 0xA3, 0x89, 0xDA, 0xAC, 0x6A, 
	/* 0x4e0 */ 0xE1, 0x18, 0x2A, 0xB1, 0xA8, 0x43, 0x61, 0x5B, 
	/* 0x4e8 */ 0xD3, 0x1F, 0xDC, 0x3B, 0x8D, 0x76, 0xF2, 0x2D, 
	/* 0x4f0 */ 0xE8, 0x8D, 0x75, 0xDF, 0x17, 0x33, 0x6C, 0x3D, 
	/* 0x4f8 */ 0x53, 0xFB, 0x7B, 0xCB, 0x41, 0x5F, 0xFF, 0xDC, 
	/* 0x500 */ 0xA2, 0xD0, 0x61, 0x38, 0xE1, 0x96, 0xB8, 0xAC, 
	/* 0x508 */ 0x5D, 0x8B, 0x37, 0xD7, 0x75, 0xD5, 0x33, 0xC0, 
	/* 0x510 */ 0x99, 0x11, 0xAE, 0x9D, 0x41, 0xC1, 0x72, 0x75, 
	/* 0x518 */ 0x84, 0xBE, 0x02, 0x41, 0x42, 0x5F, 0x67, 0x24, 
	/* 0x520 */ 0x48, 0x94, 0xD1, 0x9B, 0x27, 0xBE, 0x07, 0x3F, 
	/* 0x528 */ 0xB9, 0xB8, 0x4F, 0x81, 0x74, 0x51, 0xE1, 0x7A, 
	/* 0x530 */ 0xB7, 0xED, 0x9D, 0x23, 0xE2, 0xBE, 0xE0, 0xD5, 
	/* 0x538 */ 0x28, 0x04, 0x13, 0x3C, 0x31, 0x03, 0x9E, 0xDD, 
	/* 0x540 */ 0x7A, 0x6C, 0x8F, 0xC6, 0x07, 0x18, 0xC6, 0x7F, 
	/* 0x548 */ 0xDE, 0x47, 0x8E, 0x3F, 0x28, 0x9E, 0x04, 0x06, 
	/* 0x550 */ 0xCF, 0xA5, 0x54, 0x34, 0x77, 0xBD, 0xEC, 0x89, 
	/* 0x558 */ 0x9B, 0xE9, 0x17, 0x43, 0xDF, 0x5B, 0xDB, 0x5F, 
	/* 0x560 */ 0xFE, 0x8E, 0x1E, 0x57, 0xA2, 0xCD, 0x40, 0x9D, 
	/* 0x568 */ 0x7E, 0x62, 0x22, 0xDA, 0xDE, 0x18, 0x27, 
};
static const lws_ss_x509_t _ss_x509_isrg_root_x1 = {
	.vhost_name = "isrg_root_x1",
	.ca_der = _ss_der_isrg_root_x1,
	.ca_der_len = 1391,
};
static const lws_ss_trust_store_t _ss_ts_le_via_isrg = {
	.name = "le_via_isrg",
	.count = 1,
	.ssx509 = {
		&_ss_x509_isrg_root_x1,
	}
};

static const lws_ss_policy_t _ssp_captive_portal_detect = {
	.streamtype = "captive_portal_detect",
	.endpoint = "connectivitycheck.android.com",
	.u = {
		.http = {
			.method = "GET",
			.url = "generate_204",
			.resp_expect = 204,
			.fail_redirect = 1,
		}
	},
	.flags = 0x1,
	.priority = 0x0,
	.port = 80,
	.protocol = 0,
},
_ssp_test_stream = {
	.next = (void *)&_ssp_captive_portal_detect,
	.streamtype = "test_stream",
	.endpoint = "warmcat.com",
	.u = {
		.http = {
			.method = "GET",
			.url = "index.html",
		}
	},
	.retry_bo = &_rbo_0,
	.flags = 0x11,
	.priority = 0x0,
	.port = 443,
	.protocol = 1,
	.trust = {.store = &_ss_ts_le_via_isrg},
};
#define _ss_static_policy_entry _ssp_test_stream
/* estimated footprint 2043 (when sizeof void * = 8) */