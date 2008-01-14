/*	This file is part of NDSTrim.
	
	NDSTrim is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	
	NDSTrim is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with NDSTrim.  If not, see <http://www.gnu.org/licenses/>
	
	
	ROM size is available in four bytes at 0x80-0x83.
	Wifi data is stored on 136 bytes after ROM data.
	Filesize is checked to be at least 0x200 bytes to make sure it contains a DS cartridge header.
	Filesize is then checked to be at least the rom size+wifi to avoid errors.
	
	Sources:
	http://nocash.emubase.de/gbatek.htm
	http://forums.ds-xtreme.com/showthread.php?t=1964
	http://gbatemp.net/index.php?showtopic=44022
*/

#include <stdio.h>
#include <stdlib.h>

//#define DEBUG
#define BUFFER 1000000 //1 MB buffer size

//The rom size is located in four bytes at 0x80-0x83
//Using a struct is the only way to manually specify the number of bits
struct uint32 {
	unsigned data:32; //4*8
};

int main(int argc, char *argv[]) {
	if (argc < 2) {
		fprintf(stderr,"%s: Too few arguments.\n",argv[0]);
		fprintf(stderr,"%s: Usage: %s <input> [output]\n",argv[0],argv[0]);
		exit(1);
	}
	
	//Debug?
	char debug=0;
	#ifdef DEBUG
	debug=1;
	#endif
	
	//Open input
	#ifdef DEBUG
	printf("%s: Opening input file '%s'.\n",argv[0],argv[1]);
	#endif
	FILE *input;
	if ((input=fopen(argv[1],"rb")) == NULL) {
		fprintf(stderr,"%s: fopen() failed in file %s, line %d.\n",argv[0],__FILE__,__LINE__);
		fprintf(stderr,"%s: This is most likely because the input file doesn't exist.\n",argv[0],__FILE__,__LINE__);
		exit(1);
	}
	
	//Get input filesize
	fseek(input,0,SEEK_END);
	unsigned int filesize=ftell(input);
	#ifdef DEBUG
	printf("%s: Filesize: %d bytes.\n",argv[0],filesize);
	#endif
	
	//Check if rom is big enough to contain a DS cartridge header
	if (filesize <= 0x200) {
		fprintf(stderr,"%s: Error: '%s' is too small to contain a NDS cartridge header (corrupt rom?).\n",argv[0],argv[1]);
		exit(1);
	}
	
	//Read rom size
	fseek(input,0x80,SEEK_SET);
	struct uint32 romsize;
	fread(&romsize,sizeof(romsize),1,input);
	unsigned int saferomsize=romsize.data;
	int wifi_block=0;
	
	//Check if romsize is 0 (some commercial roms use zero, unknown reason)
	//These roms usually have the whole rom filled with stuff (unknown if it's garbage or useful stuff)
	//Known roms: 0040, 0132, 0192, 0318, and 0357 have this (All these are Japanese roms)
	if (romsize.data == 0) {
		fprintf(stderr,"%s: Warning: '%s' header romsize is 0.\n",argv[0],argv[1]);
		fprintf(stderr,"%s: Warning: This rom will be copied.\n",argv[0]);
		saferomsize=filesize;
	}
	else {
		//Check if rom is big enough to contain the rom
		if (filesize < romsize.data) {
			fprintf(stderr,"%s: Error: '%s' is too small to contain the whole rom (corrupt rom?).\n",argv[0],argv[1]);
			exit(1);
		}
		
		//Check if rom seems to have been trimmed before
		if (filesize == romsize.data) {
			fprintf(stderr,"%s: Warning: '%s' is the same size as the trimmed rom will be.\n",argv[0],argv[1]);
			fprintf(stderr,"%s: Warning: Maybe the rom have already been trimmed?\n",argv[0]);
		}
		
		//Check if rom have a wifi block
		//Wifi data is located on 136 bytes after rom data
		if (filesize >= romsize.data+136) {
			//Read wifi_data from rom
			char wifi_data[136];
			fseek(input,romsize.data,SEEK_SET);
			fread(wifi_data,1,sizeof(wifi_data),input);
			//Compare with 0x00 and 0xFF
			char wifi_compare[136];
			memset(wifi_compare,0x00,136);
			if (memcmp(wifi_data,wifi_compare,136) != 0) {
				//wifi_data is NOT filled with 0x00
				memset(wifi_compare,0xFF,136);
				if (memcmp(wifi_data,wifi_compare,136) != 0) {
					//wifi_data is NOT filled with 0xFF
					//Since wifi_data doesn't consist of 0x00 or 0xFF, the rom contains a wifi block
					wifi_block=1;
					saferomsize+=136;
				}
			}
		}
		else {
			fprintf(stderr,"%s: Warning: '%s' is too small to contain a wifi block.\n",argv[0],argv[1]);
			fprintf(stderr,"%s: Warning: This shouldn't be a problem if the rom have been properly trimmed before.\n",argv[0]);
		}
	}
	
	//Print info
	if (argc < 3 || debug) {
		printf("%s: ROM size: %d bytes.\n",argv[0],romsize.data);
		printf("%s: Safe ROM size: %d bytes.\n",argv[0],saferomsize);
		printf("%s: Wifi block? %s\n",argv[0],wifi_block?"Yes":"No");
		printf("%s: Can save: %d bytes.\n",argv[0],(filesize-saferomsize));
	}
	
	//Output trimmed rom
	if (argc >= 3) {
		//Open output
		#ifdef DEBUG
		printf("%s: Opening output file '%s'.\n",argv[0],argv[2]);
		#endif
		FILE *output;
		if ((output=fopen(argv[2],"wb")) == NULL) {
			fprintf(stderr,"%s: fopen() failed in file %s, line %d.\n",argv[0],__FILE__,__LINE__);
			exit(1);
		}
		
		//Reset input pos
		rewind(input);
		
		//Start copying
		#ifdef DEBUG
		printf("%s: Copying data.\n",argv[0]);
		#endif
		char buffer[BUFFER];
		unsigned int fpos=0;
		unsigned int tocopy=BUFFER;
		while (fpos < saferomsize) {
			if (fpos+BUFFER > saferomsize) {
				tocopy=saferomsize-fpos;
			}
			fread(buffer,tocopy,1,input);
			fwrite(buffer,tocopy,1,output);
			fpos+=tocopy;
		}
		
		//Done
		printf("%s: Trimmed '%s' to %d bytes (saved %.2f MB).\n",argv[0],argv[1],saferomsize,(filesize-saferomsize)/(float)1000000);
		
		//Close output
		#ifdef DEBUG
		printf("%s: Closing output.\n",argv[0]);
		#endif
		if (fclose(output) == EOF) {
			fprintf(stderr,"%s: fclose() failed in file %s, line %d.\n",argv[0],__FILE__,__LINE__);
			exit(1);
		}
	}
	
	//Close input
	#ifdef DEBUG
	printf("%s: Closing input.\n",argv[0]);
	#endif
	if (fclose(input) == EOF) {
		fprintf(stderr,"%s: fclose() failed in file %s, line %d.\n",argv[0],__FILE__,__LINE__);
		exit(1);
	}
	
	return 0;
}

