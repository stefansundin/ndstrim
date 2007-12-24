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
	
	//Check if file is big enough to contain a DS cartridge header
	if (filesize <= 0x200) {
		fprintf(stderr,"%s: Error: '%s' is too small to contain a NDS cartridge header (corrupt rom?).\n",argv[0],argv[1]);
		exit(1);
	}
	
	//Read rom size
	fseek(input,0x80,SEEK_SET);
	struct uint32 romsize;
	fread(&romsize,sizeof(romsize),1,input);
	unsigned int newsize=romsize.data+136; //Wifi data is located on 136 bytes after rom data
	
	//Check if file is big enough to contain the rom+wifi
	if (filesize < newsize) {
		fprintf(stderr,"%s: Error: '%s' is too small to contain the whole rom+wifi (corrupt rom?).\n",argv[0],argv[1]);
		exit(1);
	}
	
	//Check if this file seems to have been trimmed before
	if (filesize == newsize) {
		fprintf(stderr,"%s: Warning: '%s' is the same size as the trimmed rom will be (already trimmed?).\n",argv[0],argv[1]);
	}
	
	//Print info
	if (argc < 3 || debug) {
		printf("%s: ROM size: %d bytes.\n",argv[0],romsize.data);
		printf("%s: ROM size + wifi: %d bytes.\n",argv[0],newsize);
		printf("%s: Can save: %d bytes.\n",argv[0],(filesize-newsize));
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
		while (fpos < newsize) {
			if (fpos+BUFFER > newsize) {
				tocopy=newsize-fpos;
			}
			fread(&buffer,tocopy,1,input);
			fwrite(&buffer,tocopy,1,output);
			fpos+=tocopy;
		}
		
		//Done
		printf("%s: Trimmed '%s' to %d bytes (saved %.2f MB).\n",argv[0],argv[1],newsize,(filesize-newsize)/(float)1000000);
		
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

