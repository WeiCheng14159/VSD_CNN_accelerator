#!/usr/bin/perl


@SUPPORT_TECHVERSION=("1");

use Math::BigFloat;
#Math::BigFloat->accuracy(30);

if (@ARGV < 1) {
    die ("Usage: $0 lef_file [-t techfile]\n");
}
my $lefName="undefine";

#default value
$U_UNIT =0.001;
my $techfile="lef2gds_U18.tech";

for (my $i=0;$i<@ARGV;$i++){
    if($ARGV[$i] =~ /-t/){
        $i++;
        $techfile=$ARGV[$i];
    }elsif($ARGV[$i] =~ /-h/){
        die ("Usage: $0 lef_file [-t techfile]\n");
    }else{
        $lefName=$ARGV[$i] ;
    }
}

$lefName =~ /(\S+)\./;
my $libName = $1;
$libName= $lefName if ($libName eq "");
my $gdsname = $libName.".gds";
die ("leffile $lefName not found\n") if (!-e $lefName);

%PINLAYERMAP=();
%OBSLAYERMAP=();
%PRBOUNDARY=();

&read_tech_map($techfile);

open (lef,"<$lefName") or die ("Failed to open lef $lefName\n");
open (gds,">$gdsname");
binmode(gds);
my $stage="out_macro";
my $curcell="";
my $curpin="";
my $curlayer="";
my @pins=();
my $xoffset;
my $yoffset;

&gds_header();
&new_lib($libName);
print("== Read lef $lefName ==\n");

my $line="";
while(<lef>){
    chomp;
    s/#.*//;
    if(!(/PIN/ or /PORT/ or /END/ or /OBS/ or /MACRO/)){
        $line=$line." ".$_;
        if(/;\s*$/){
            $_=$line;
            $line="";
        }else{
            next;
        }
    }
    s/^\s+//;
    next if (/^$/);
    if(($stage eq "out_macro") and (/^MACRO\s+(\w+)/)){
        $curcell=$1;      
        $stage="in_macro";
        @pins=();
        &new_cell($curcell);
        print("Cell: $curcell\n");
        next;
    }
    if($stage eq "in_macro") {
        if(/^FOREIGN\s+(\S+)\s+(\S+)\s+(\S+)/){
            $xoffset=$2;
            $yoffset=$3;
        }elsif(/^PIN\s+(\S+)/){
            $stage="in_pin";
            $curpin=$1;
            push (@pins,$curpin);
        }elsif(/^OBS\b/){
            $stage="in_obs";
        }elsif(/^SIZE\s+(\S+)\s+BY\s+(\S+)/){
            my $gdslayer=$PRBOUNDARY{gdslayer};
            my $purpose=$PRBOUNDARY{purpose};
            my $rx=$1;
            my $ty=$2;
            my $centx=$rx/2;
            my $centy=$ty/2;
            &create_rect($gdslayer,$purpose,0,0,$rx,$ty);
            &create_text($curcell,$gdslayer,$purpose,$centx,$centy,1);
        }elsif(/^END\s+(\w+)/){
            die("ERROR: parse lef failed before line $.\n") if($curcell ne $1);
            $stage = "out_macro";
            #print("PINS: @pins\n");
            &endcell();
            @pins=();
            $curcell = "";
        }
        next;
    }
    if($stage eq "in_pin") {
        if (/^PORT\s*$/){
            $stage="in_port";
            $curlayer="";
        }elsif(/^END\s+(\S+)\s*$/){
            die("ERROR: parse lef failed before line $.\n") if($curpin ne $1);
            $stage="in_macro";
        }
        next;
    }
    if($stage eq "in_port"){
        if(/^LAYER\s+(\w+)/){
            $curlayer=$1;
            if(!defined $PINLAYERMAP{$curlayer}){
                print("WARN: layer $curlayer not defined in $techfile\n");
            }
        }elsif(/^RECT\b/){
            die ("lef parse failed at line $.\n") if($curlayer eq "");
            s/\s*;//;
            next if(!defined $PINLAYERMAP{$curlayer});
            if($PINLAYERMAP{$curlayer}->{draw} =~ /y/){
                my ($rect,$lx,$by,$rx,$ty)=split(/\s+/);
                my $centx=($lx+$rx)/2;
                my $centy=($by+$ty)/2;
                my $gdslayer = $PINLAYERMAP{$curlayer}->{gdslayer};
                my $purpose = $PINLAYERMAP{$curlayer}->{purpose};
                my $textlayer = $PINLAYERMAP{$curlayer}->{textlayer};
                my $textpurpose = $PINLAYERMAP{$curlayer}->{textpurpose};
                &create_rect($gdslayer,$purpose,$lx,$by,$rx,$ty);
                &create_text($curpin,$textlayer,$textpurpose,$centx,$centy,0.5);
            }
        }elsif(/^POLYGON/){
            die ("lef parse failed at line $.\n") if($curlayer eq "");
            s/\s*;//;
            next if(!defined $PINLAYERMAP{$curlayer});
            if ( $PINLAYERMAP{$curlayer}->{draw} =~ /y/ ){
                my ($polygon,@xy)=split(/\s+/);
                my $gdslayer = $PINLAYERMAP{$curlayer}->{gdslayer};
                my $purpose = $PINLAYERMAP{$curlayer}->{purpose};
                &create_polygon($gdslayer,$purpose,@xy);
            }
        }elsif(/^END\s*$/){
            $stage="in_pin";
        }
        next;
    }
    if($stage eq "in_obs"){
        if(/^LAYER\s+(\w+)/){
            $curlayer=$1;
            if((!defined $OBSLAYERMAP{$curlayer})&&($curlayer ne "OVERLAP")){
                print("WARN: obs layer $curlayer not defined in $techfile\n");
            }
        }elsif(/^RECT\b/){
            die ("lef parse failed at line $.\n") if($curlayer eq "");
            s/\s*;//;
            next if((!defined $OBSLAYERMAP{$curlayer}) or ($curlayer eq "OVERLAP"));
            if($OBSLAYERMAP{$curlayer}->{draw} =~ /y/){
                my ($rect,$lx,$by,$rx,$ty)=split(/\s+/);
                my $gdslayer = $OBSLAYERMAP{$curlayer}->{gdslayer};
                my $purpose = $OBSLAYERMAP{$curlayer}->{purpose};
                &create_rect($gdslayer,$purpose,$lx,$by,$rx,$ty);
            }
        }elsif(/^POLYGON/){
            die ("lef parse failed at line $.\n") if($curlayer eq "");
            s/\s*;//;
            next if((!defined $OBSLAYERMAP{$curlayer}) or ($curlayer eq "OVERLAP"));
            if ( $OBSLAYERMAP{$curlayer}->{draw} =~ /y/ ){
                my ($polygon,@xy)=split(/\s+/);
                my $gdslayer = $OBSLAYERMAP{$curlayer}->{gdslayer};
                my $purpose = $OBSLAYERMAP{$curlayer}->{purpose};
                &create_polygon($gdslayer,$purpose,@xy);
            }
        }elsif(/^END\s*$/){
            $stage="in_macro";
        }
        next;
    }
}
die ("parse lef fail \n") if($stage ne "out_macro");
&endlib();
close(lef);
close(gds);
exit;


sub read_tech_map(){
    my $techfile=shift;
    print("== Read techfile $techfile ==\n");
    open (fp,"$techfile") or die("open techfile $techfile fail\n");
    while(<fp>){
        s/#.*//;
        next if (/^\s*$/);
        if(/TECHVERSION\s+(\S+)/){
            my $match=0;
            my $techversion=$1;
            foreach my $version (@SUPPORT_TECHVERSION){
                $match=1 if($version eq $techversion);
            }
            print("WARN: Unsupported techfile version: $techfile\n") if($match==0);
            next;
        }
        if(/U_UNIT\s+(0.\d+)/){
            $U_UNIT=$1;
            next;
        }
        if(/LAYER/){
            s/\t//g;
            s/^\s+//;
            my ($tmp,$leflayer,$leftype,@L)=split(/\s+/);
            if($leftype =~ /PIN/i){
                $PINLAYERMAP{$leflayer}={gdslayer=>$L[0],purpose=>$L[1],
                                         textlayer=>$L[2],textpurpose=>$L[3],draw=>$L[4]};
            }elsif($leftype =~ /OBS/i){
                $OBSLAYERMAP{$leflayer}={gdslayer=>$L[0],purpose=>$L[1],draw=>$L[2]};
            }
            if($leflayer =~ /boundary/i){
                %PRBOUNDARY=(gdslayer=>$L[0],purpose=>$L[1],draw=>$L[2]);
            }
        }
    }
    close(fp);
}

sub create_text(){
    my ($string,$layer,$datatype,$x,$y,$size)=@_;
    # x and y in micron
    print gds pack("H8","00040c00");  #text definition
    my $layer_hex=sprintf("%4x",$layer);
    print gds pack("H12","00060d02".$layer_hex);
    my $datatype_hex=sprintf("%4x",$datatype);
    print gds pack("H12","00061602".$datatype_hex); #texttype (purpose)
    print gds pack("H12","000617010005"); #presentation (org at middle)
    #print gds pack("H12","00061A018006"); #strans (abs loc and abs angle)
    print gds pack("H12","00061A010000"); #strans (abs loc and abs angle)
    my $size_string=&float($size,8);
    print gds pack("H24","000c1b05".$size_string); #mag (size)
    my $x_m=Math::BigFloat->new($x /$U_UNIT);
    my $y_m=Math::BigFloat->new($y /$U_UNIT);
    my $x_hex=substr(sprintf("%8x",$x_m),-8);
    my $y_hex=substr(sprintf("%8x",$y_m),-8);
    #my $x_hex=substr(sprintf("%8x",sprintf("%s",$x /$U_UNIT)),-8);
    #my $y_hex=substr(sprintf("%8x",sprintf("%s",$y /$U_UNIT)),-8);
    print gds pack("H24","000c1003".$x_hex.$y_hex); #xy
    my $string_length=length($string);
    if ($string_length%2 ==0){
        my $record_lentgh_hex=sprintf("%4x",$string_length+4);
        print gds pack("H8",$record_lentgh_hex."1906");
        print gds ($string);
    }else{
        my $record_lentgh_hex=sprintf("%4x",$string_length+5);
        print gds pack("H8",$record_lentgh_hex."1906");
        print gds ($string);
        print gds pack("H2","00");
    }
    print gds pack("H8","00041100"); #end element
}

sub create_rect(){
    my ($layer,$datatype,$lx,$by,$rx,$ty)=@_;
    &create_polygon($layer,$datatype,$lx,$by,$rx,$by,$rx,$ty,$lx,$ty);
}

sub create_polygon(){
    my ($layer,$datatype,@xy)=@_;
    print gds pack("H8","00040800"); #boundary define
    my $layer_hex=sprintf("%4x",$layer);
    print gds pack("H12","00060d02".$layer_hex); #layer
    my $datatype_hex=sprintf("%4x",$datatype);
    print gds pack("H12","00060e02".$datatype_hex);
    my @xy_hex=();
    for(my $i=0;$i<@xy;$i++){
        my $xy_m=Math::BigFloat->new($xy[$i]/$U_UNIT);
        my $xy_mint=int($xy_m);
        printf("ERROR, %s not fit user unit: $U_UNIT .\n",$xy[$i]) if($xy_m != $xy_mint);
        #$xy_hex[$i]=substr(sprintf("%8x",sprintf("%s",$xy[$i]/$U_UNIT)),-8);
        $xy_hex[$i]=substr(sprintf("%8x",$xy_m),-8); #substr -8 is required for negative value
    }
    my $xy_join=join("",@xy_hex,$xy_hex[0],$xy_hex[1]);
    my $total_char=length($xy_join)+8; #8 is for record header
    my $total_char_hex=sprintf("%4x",$total_char/2);
    print gds pack("H$total_char", $total_char_hex."1003".$xy_join);
    my $endel = "00041100";
    print gds pack("H8",$endel);  #end element
}
sub new_lib(){
    my ($libname)=@_;
    my $timeform=&time_form;
    print gds pack("H56","001c0102".$timeform.$timeform); #bgnlib
    my $libname_length=length($libname);
    if ($libname_length%2 ==0){
        my $record_lentgh_hex=sprintf("%4x",$libname_length+4);
        print gds pack("H8",$record_lentgh_hex."0206");
        print gds ($libname);
    }else{
        my $record_lentgh_hex=sprintf("%4x",$libname_length+5);
        print gds pack("H8",$record_lentgh_hex."0206");
        print gds ($libname);
        print gds pack("H2","00");
    }

    my $generation = "000622020003"; #fix
    print gds pack("H12",$generation);
    my $user_unit=&float($U_UNIT,8);
    #my $user_unit="3e4189374bc6a7ef";   #0.001 
    my $database_unit=&float(0.000000001,8);
    #my $database_unit="3944b82fa09b5a51"; # 0.000000001 meter
    print gds pack("H40","00140305".$user_unit.$database_unit);
}
sub new_cell(){
    my ($cellname)=@_;
    my $timeform=&time_form;
    print gds pack("H56","001c0502".$timeform.$timeform); #bgnstr
    my $cellname_length=length($cellname);
    if ($cellname_length%2 ==0){
        my $record_lentgh_hex=sprintf("%4x",$cellname_length+4);
        print gds pack("H8",$record_lentgh_hex."0606");
        print gds ($cellname);
    }else{
        my $record_lentgh_hex=sprintf("%4x",$cellname_length+5);
        print gds pack("H8",$record_lentgh_hex."0606");
        print gds ($cellname);
        print gds pack("H2","00");
    }
}

sub time_form(){
    my ($sec,$min,$hour,$mday,$mon,$year) =localtime(time);
    $mon++;
    my $timeform=sprintf("%4x%4x%4x%4x%4x%4x",$year,$mon,$mday,$hour,$min,$sec);
    return($timeform);
}

sub float(){
    #translate a fixpoint value to 8/4 byte floating point representation
    # 8byte representation:
    # seeeeeee mmmmmmmm mmmmmmmm mmmmmmmm mmmmmmmm mmmmmmmm mmmmmmmm mmmmmmmm
    # 4byte representation:
    # seeeeeee mmmmmmmm mmmmmmmm mmmmmmmm 
    # value = (1-s) M*16^E  , 1 > M >= 1/16
    # type: 8 or 4 (8byte or 4byte)
    my ($value,$type)=@_;
    $type=8 if ($type=="");
    my @dec2hex=("0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f");
    my $sign=0;
    if($value<0){
        $value= abs($value);
        $sign=1; 
    }
    my $value_t=$value;
    my $power;
    my $value_exp;
    my $value_manti;
    if($value_t>=1){
        $power=1;
        $value_exp=0;
        while($value_t>=1){
            $value_t=$value_t/16;
            $value_exp++;
            $power=$power*16;
        }
        $value_manti=$value /$power;
    }else{
        $power=1/16;
        $value_exp=1;
        while($value_t<1){
            $value_t=$value_t*16;
            $value_exp--;
            $power=$power*16;
        }
        $value_manti=$value*$power;
    }
    #my $mantissz="00000000000000";
    my $mantissz="";
    my $mantilength=$type*2-2;
    for(my $i=0; $i<$mantilength ; $i++){
        my $value_manti_mtply16=Math::BigFloat->new(16*$value_manti);
        my $integer=int($value_manti_mtply16);
        my $fraction=$value_manti_mtply16-$integer;
        #substr($mantissz,$i,1)=$dec2hex[$integer];
        $mantissz=$mantissz.$dec2hex[$integer];
        $value_manti=$fraction;
    }
    my $exp_norm=$value_exp+64;

    $exp_norm=$exp_norm+128 if ($sign==1); #neg value
    my $exp_hex=sprintf("%2x",$exp_norm);
    my $total=$exp_hex.$mantissz;
    return($total);
}

sub gds_header(){
    my $header = "000600020005"; #version 5 
    print gds pack("H12",$header);
}
sub endcell(){
    my $endstr="00040700";  
    print gds pack ("H8",$endstr);
}
sub endlib(){
    my $endlib="00040400";
    print gds pack ("H8",$endlib);
}
