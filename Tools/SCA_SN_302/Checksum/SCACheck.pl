#!/usr/bin/perl -w

use strict;
use warnings;

use Cwd;
use Sys::Hostname;
use Time::Local;

################################################################################
#GLOBAL
################################################################################
my $g_file;
my $g_tempFolder;
my $g_SCAMajorVersion;
my $g_SCAMinorVersion;
my $g_SCAPatchVersion;
my $g_verifyValue;

my $g_chkTmpFile;
my $g_testCFile;
my $g_testExeFile;

my $g_ccode = '
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv)
{
    unsigned int verifyValue = $g_verifyValue;
    
    char buffer [50];
    FILE *chkinf0;
    unsigned int i, chkvalue;
    
    chkvalue = 0;
    chkinf0 = fopen(argv[1], "r");
    while (fgets(buffer, sizeof(buffer), chkinf0))
    {
	    for (i = 0; buffer[i]; i++)
	    {
		    chkvalue += buffer[i];
		    chkvalue += (chkvalue << 10);
		    chkvalue ^= (chkvalue >> 6);
	    }
    }
    chkvalue += (chkvalue << 3);
    chkvalue ^= (chkvalue >> 11);
    chkvalue += (chkvalue << 15);
    fclose(chkinf0);
    
    if(chkvalue == verifyValue)
    {
        printf("No change!\n");
    }
    else
    {
        /*printf("Diff! %u(check: %u)\n", chkvalue, verifyValue);*/
        printf("File is changed!\n");
        return(1);
    }
    
    return(0);
} 
'; 


################################################################################
#checkArguments()
################################################################################
sub checkArguments()
{
    my $argvCount = scalar @ARGV;

    if ( $argvCount ne 2 )
    {
        print "\n=======================================================================\n\n";
        print " Usage of SCACheck.pl                                                    \n\n";
        print " perl SCACheck.pl File TempFolder                                        \n\n";
        print " Ex: perl SCACheck.pl /home/MMAP_128.h /home/temp                        \n\n";
        print "=========================================================================\n\n";
        goto _ON_ERR;
    }
    
    return 0;
    
_ON_ERR:

    return 1;    
}

################################################################################
#initGlobalParameters()
################################################################################
sub initGlobalParameters()
{    
    $g_file             = $ARGV[0];
    $g_tempFolder       = $ARGV[1];
    $g_SCAMajorVersion  = "";
    $g_SCAMinorVersion  = "";
    $g_SCAPatchVersion  = "";
    $g_verifyValue      = 0;

    $g_chkTmpFile       = "$g_tempFolder/a.h";
    $g_testCFile        = "$g_tempFolder/test.c";
    $g_testExeFile      = "$g_tempFolder/test.exe";

    return 0;
    
_ON_ERR:

    return 1;
}

################################################################################
#genTestCCode()
################################################################################
sub genTestCCode()
{        
    my $testFile         = $_[0];
    
    if(-e "$testFile")
    {
        system("rm -f $testFile");
    }
    if(open(FH_CFILE, "> $testFile"))
    {  
        $g_ccode =~ s/\$g_verifyValue/$g_verifyValue/g;
        print FH_CFILE "$g_ccode\n";       
        close(FH_CFILE);
    }
    else
    {
        print "[DBG_ERROR][",__LINE__,"] Cannot open temp file $testFile\n";
        goto _ON_ERR;
    }

    return 0;
    
_ON_ERR:

    return 1;
}

################################################################################
#makTestCCode()
################################################################################
sub makTestCCode()
{        
    my $testCFile       = $_[0];
    my $testExeFile     = $_[1];
    
    my $cmd;
    my $ret;
    
    if(-e "$testExeFile")
    {
        system("rm -f $testExeFile");
    }
    
    # gcc -s -O2 -Wall -ansi -pedantic test.c -o test.exe;chmod 777 test.exe

    $cmd = "gcc -s -O2 -Wall -ansi -pedantic $testCFile -o $testExeFile";
    print "$cmd\n";
    $ret = system($cmd);
    if(0 ne $ret)
    {
        print "[DBG_ERROR][",__LINE__,"] Compile error!\n";
        goto _ON_ERR;
    }
    
    $cmd = "chmod 777 $testExeFile";
    print "$cmd\n";
    $ret = system($cmd);
    if(0 ne $ret)
    {
        print "[DBG_ERROR][",__LINE__,"] Failed to change file mode!\n";
        goto _ON_ERR;
    }
    
    if(! -e "$testExeFile")
    {
        print "[DBG_ERROR][",__LINE__,"] Error!\n";
        goto _ON_ERR;
    }
    
    return 0;
    
_ON_ERR:

    return 1;
}

################################################################################
#testFile()
################################################################################
sub testFile()
{        
    my $exeFile         = $_[0];
    my $chkFile         = $_[1];
    
    my $cmd;
    my $ret;

    $cmd = "$exeFile $chkFile";
    print "$cmd\n";
    $ret = system($cmd);
    if(0 ne $ret)
    {
        print "[WARING][",__LINE__,"] $g_file is changed.\n";
        print "Please don't modify the file.\n";
        goto _ON_ERR;
    }
        
    return 0;
    
_ON_ERR:

    return 1;
}

################################################################################
#main()
################################################################################
sub main()
{
    my $flagNeedCheck;
    my $lineData;
    
    if(0 ne &checkArguments())
    {
        goto _ON_ERR;
    }
       
    if(0 ne &initGlobalParameters())
    {
        goto _ON_ERR;
    }
    
    $flagNeedCheck = 0;
    if(open(FH_INFILE, "< $g_file"))
    {
        if(-e "$g_chkTmpFile")
        {
            system("rm -f $g_chkTmpFile");
        }
        if(open(FH_OUTFILE, "> $g_chkTmpFile"))
        {
            ;
        }
        else
        {
            print "[DBG_ERROR][",__LINE__,"] Cannot open temp file $g_chkTmpFile\n";
            close(FH_INFILE);
            goto _ON_ERR;
        }
        
        # 1. generate new header file for checking
        #    A. get SCA tool version
        #    B. get check value
        #    C. remove last line (/* CHK_VALUE = xxxxxx */)
        while($lineData = <FH_INFILE>)
        {
            ##define SCA_TOOL_VERSION            "SN SCA V1.1.1 "
            if($lineData =~ /^\#define\s+SCA_TOOL_VERSION\s+\"SN\s+SCA\s+V(\d+)\.(\d+)\.(\d+)\s+\"/)
            {
                $g_SCAMajorVersion  = "$1";
                $g_SCAMinorVersion  = "$2";
                $g_SCAPatchVersion  = "$3";
                $flagNeedCheck = 1;
            }
            if($lineData =~ /\/\*\s+CHK_VALUE\s+\=\s+(\d+)\s+\*\//)
            {
                $g_verifyValue = $1;
                $flagNeedCheck = 1;
                last;
            }
            $lineData =~ s/\r\n/\n/; # dos to unix
            print FH_OUTFILE "$lineData";
        }
        close(FH_OUTFILE);
        close(FH_INFILE);
        
        if($flagNeedCheck eq 1)
        {
            # 2. generate test.c
            if(0 ne &genTestCCode($g_testCFile))
            {
                goto _ON_ERR;
            }
            # 3. compile test.c (use gcc)
            if(0 ne &makTestCCode($g_testCFile, $g_testExeFile))
            {
                goto _ON_ERR;
            }
            # 4. test file
            if(0 ne &testFile($g_testExeFile, $g_chkTmpFile))
            {
                goto _ON_ERR;
            }
        }
        else
        {
            print "Old version generated file.(ignored)\n";
        }
    }
    else
    {
        print "[DBG_ERROR][",__LINE__,"] Cannot open file $g_file\n";
        goto _ON_ERR;
    }
    
    # remove temp file
    if(-e "$g_chkTmpFile")
    {
        system("rm -f $g_chkTmpFile");
    }
    if(-e "$g_testCFile")
    {
        system("rm -f $g_testCFile");
    }
    if(-e "$g_testExeFile")
    {
        system("rm -f $g_testExeFile");
    }
     
    return 0;
    
_ON_ERR:

    exit 1;
}

&main();

__END__

