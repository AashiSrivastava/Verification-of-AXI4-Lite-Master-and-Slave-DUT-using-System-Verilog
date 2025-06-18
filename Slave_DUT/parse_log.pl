use warnings    ;
use Getopt::Long; 
use File::Copy  ;
use File::Compare;
use Time::Piece;
use DBI;
use Term::ANSIColor;

my $hang_pat = $ARGV[0];
my $mismatch_pat = $ARGV[1];
my $pass_pat = $ARGV[2];
my $logpath = $ARGV[3];
my $dec_error = $ARGV[4];
my $fatal = $ARGV[5];
my $fatal_;
my $error_;
my $pass_;
my $retire_;
my $dec_error_;

$hang_ = qx(grep '$hang_pat' $logpath | wc -l);
$mismatch_ = qx(grep '$mismatch_pat' $logpath | wc -l);
$fatal_ = qx(grep '$fatal' $logpath | wc -l);
$dec_error_ = qx(grep '$dec_error' $logpath | wc -l);
$pass_ = qx(grep '$pass_pat' $logpath | wc -l);
$retire_ = qx(grep '0retire' $logpath | wc -l);

#print "DBG : $hang_\n";
#print "DBG : $mismatch_\n";
#print "DBG : $pass_\n";
if($retire_ > 0 ) {
  open (RES, ">", "results.txt" ) or die "could not open:$!";
  open (FILE, "<", "run.log") or die "could not open:$!";
  while(<FILE>) { print RES if ($_ =~ /0retire/); }
  close(FILE); close(RES);
  system('echo "NOT ALL DRIVEN TIDs RETIRED" >> results.txt');
  system("touch failed");
        print color('bold red');
        print "========================================================================================================\n";
        print "=========================================   TID RETIRE FAIL   ==========================================\n";
        print "========================================================================================================\n";
}
  
  #system('grep \'retire\' $logpath > results.txt');
if($fatal_ > 0) {
  system('echo "HUNG/KILLED : HANG" > results.txt');
  system("touch failed");
         print color('bold red');
        print "========================================================================================================\n";
        print "===============================================   FAIL   ===============================================\n";
        print "========================================================================================================\n";

}elsif($mismatch_ > 0) {
  system('echo "TEXT IMAGES _DONOT_ MATCH" >> results.txt');
  system("touch failed");
         print color('bold red');
        print "========================================================================================================\n";
        print "===============================================   FAIL   ===============================================\n";
        print "========================================================================================================\n";
}
elsif($hang_ > 0) {
  system('echo "HUNG/KILLED : HANG" > results.txt');
  system("touch failed");
         print color('bold red');
        print "========================================================================================================\n";
        print "===============================================   FAIL   ===============================================\n";
        print "========================================================================================================\n";
}
elsif($dec_error_ > 0) {
  system('echo "DEC ERROR" >> results.txt');
        print color('bold yellow');
        print "========================================================================================================\n";
        print "===============================================   DEC ERROR   ==========================================\n";
        print "========================================================================================================\n";

}
elsif($pass_ > 0) {
  system('echo "TEXT IMAGES MATCH" >> results.txt');
        print color('bold green');
        print "========================================================================================================\n";
        print "===============================================   PASS   ===============================================\n";
        print "========================================================================================================\n";

}
else {
  system('echo "HUNG/KILLED : KILLED" >> results.txt');
  system("touch failed");
         print color('bold red');
        print "========================================================================================================\n";
        print "===============================================   FAIL   ===============================================\n";
        print "========================================================================================================\n";
}
