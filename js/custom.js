function checkform2(){
    if (checkform()) return true;
    return false;
}
function checkform(){
 var valid=new Validation(document.forms[0],{ onSubmit : false,immediate: true });
 return valid.validate();
}

function setat(){

if (document.forms[0].currency.value=="HUF"){
  document.forms[0].language.value=""
}else {
  document.forms[0].language.value="export--export";
}
}

function dattrans(n,c){
  var d = $(n);
  if (d.value.length==4 && !/[^\d]/.test(d.value)) {
    var most= new Date();
    ev=most.getYear()
    if (ev<1000) {ev+=1900;};
    var tit=d.title;
    tit=tit.replace("(","");
    tit=tit.replace(")","");
    tit=tit.replace(" ","");
    tit=tit.replace("mm",d.value.substr(0,2));
    tit=tit.replace("dd",d.value.substr(2,2));
    tit=tit.replace("yyyy",ev);
    tit=tit.replace("yy",ev.toString().substr(2,2));
    d.value=tit;
  }    
  if(c==1) {
    document.forms[0].transdate.value=d.value;
    document.forms[0].duedate.value=d.value;
  }    
}

function quotchange(n){
    var d = $(n);
    d.value=d.value.replace(/\"/g,"\'");
}

function valtozik(){
document.forms[0].action.value="Jump";
//alert(document.forms[0].action.value);
  document.forms[0].submit("Jump");
}

function regaccall(){
 if(document.forms[0].accno_1){
  var accn=document.forms[0].accno_1.value;
  var d=$('regacc_'+accn);
  if (d && document.forms[0].regsource) {document.forms[0].regsource.value=d.value};
  refall(); 
 }
}
function refall(){
  if (document.forms[0].regsource){
    if (document.forms[0].regsource.value !=0) {document.forms[0].reference.type='hidden';}
     else {document.forms[0].reference.type='text'};
  }
}

function tolt(ssz){
  for (i = 1; i < ssz; i++){
    eval("document.forms[0].ship_"+i+".value=document.forms[0].qty_"+i+".value")
  }
}
 