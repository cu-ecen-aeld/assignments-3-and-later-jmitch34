//import libs
#include <syslog.h>
#include <stdio.h>
#include <stdbool.h>

int main(int argc, char *argv[]){
	openlog(NULL,0,LOG_USER);
	//validate argc is equal to 2
	if (argc != 3){
		//syslog LOG_ERR
		syslog(LOG_ERR, "invalid number of arguments: %d", argc);		 
		return 1;
	}

	char* writefile = argv[1];
	char* writestr =  argv[2];

	FILE *fptr = fopen(writefile, "w");
	if (fptr == NULL){
		syslog(LOG_ERR, "failed to write string to file");
		return 1;
	}
	fprintf(fptr,"%s", writestr);
	syslog(LOG_DEBUG, "Writing %s to %s", writefile, writestr);
	fclose(fptr);

	return 0;
}
