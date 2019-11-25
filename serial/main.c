#include<stdio.h> 
#include<stdlib.h>

// Main program
int main() 
{ 
	// Open input file
	FILE* in_file = fopen("hackathon.ppm","rb"); 
	if (in_file==NULL){ 
		printf("File does not exist.");
		return 0;
	} 

	// Read file format, # of pixels in x and y dim, max value for each channel
	char fmt[10];
	char max[10];
	int dimx;
	int dimy;

	fscanf(in_file, "%s", fmt);
	fscanf(in_file, "%d", &dimx);
	fscanf(in_file, "%d", &dimy);
	fscanf(in_file, "%s%*[\n]", max);

	// Allocate memory for array to hold RGB values for all pixels
	unsigned char *rgb_image = (unsigned char*)malloc(dimx*dimy*3*sizeof(unsigned char));

	// Read in pixel data from input file
	fread(rgb_image, dimx*dimy*3, sizeof(unsigned char), in_file);
	fclose(in_file);

	/* Calculate grayscale values based on RGB values and write output file --- */

	// Allocate memory for array to hold grayscale values for all pixels
	unsigned char *gray_image = (unsigned char*)malloc(dimx*dimy*sizeof(unsigned char));

	// Calculate grayscale values for all pixels
	int i, j;
	for(j=0; j<dimy; j++){
		for(i=0; i<dimx; i++){
			gray_image[j*dimx+i] = rgb_image[3*(j*dimx+i)+0] * 0.21 + rgb_image[3*(j*dimx+i)+1] * 0.72 + rgb_image[3*(j*dimx+i)+2] * 0.07;
		}
	}

  // Write pixels to PGM P5 formatted file
  FILE *out_file = fopen("output.pgm", "wb");
  fprintf(out_file, "P5\n%d %d\n%d\n", dimx, dimy, 255);
  fwrite(gray_image, sizeof(unsigned char), dimx*dimy, out_file);
  fclose(out_file);

	free(rgb_image);
	free(gray_image);
  
	return 0; 
} 
