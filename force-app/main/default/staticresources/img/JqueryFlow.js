/* Copyright (c) 2008 Kean Loong Tan http://www.gimiti.com/kltan
 * Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php)
 * jFlow
 * Version: 1.1 (May 22, 2008)
 * Requires: jQuery 1.2+
 */
(function(A){
A.fn.jFlow=function(D){
var E=A.extend({},A.fn.jFlow.defaults,D);
var F=0;var B=A(".jFlowControl").length;
A(this).find(".jFlowControl").each(function(G){A(this).click(
function(){
A(".jFlowControl").removeClass("jFlowSelected");
A(this).addClass("jFlowSelected");
var H=Math.abs(F-G);
A(E.slides).animate({marginLeft:"-"+(G*A(E.slides).find(":first-child").width()+"px")},E.duration*(H));
F=G
})});

A(E.slides).before('<div id="jFlowSlide"></div>').appendTo("#jFlowSlide");A(E.slides).find("div").each(function(){A(this).before('<div class="jFlowSlideContainer"></div>').appendTo(A(this).prev())});A(".jFlowControl").eq(F).addClass("jFlowSelected");var C=function(G){A("#jFlowSlide").css({position:"relative",width:E.width,height:E.height,overflow:"hidden"});A(E.slides).css({position:"relative",width:A("#jFlowSlide").width()*(A(".jFlowControl").length+1)+"px",height:A("#jFlowSlide").height()+"px",overflow:"hidden"});A(E.slides).children().css({position:"relative",width:A("#jFlowSlide").width()+"px",height:A("#jFlowSlide").height()+"px","float":"left"});A(E.slides).css({marginLeft:"-"+(F*A(E.slides).find(":first-child").width()+"px")})};C();A(window).resize(function(){C()});

//copy the first slide
$(".jFlowSlideContainer").eq(0).clone().appendTo('#slides');


setInterval(function(){
	if(F<B){
		F++
	}else {
		F = 0;
	}
	A(".jFlowControl").removeClass("jFlowSelected");
	A(E.slides).animate({marginLeft:"-"+(F*A(E.slides).find(":first-child").width()+"px")},E.duration, function(){
		if(F == B){
			F = 0;
			A(E.slides).css({marginLeft: 0});
		}
	});
	J = (F == B) ? 0 : F;
	A(".jFlowControl").eq(J).addClass("jFlowSelected");
}, 5000);

A(".jFlowPrev").click(
function(){
if(F>0){
	F--	
}
A(".jFlowControl").removeClass("jFlowSelected");
A(E.slides).animate({marginLeft:"-"+(F*A(E.slides).find(":first-child").width()+"px")},E.duration);
A(".jFlowControl").eq(F).addClass("jFlowSelected")});

A(".Select").click(function(){
if(F<B-1){
	F++
}
A(".jFlowControl").removeClass("jFlowSelected");
A(E.slides).animate({marginLeft:"-"+(F*A(E.slides).find(":first-child").width()+"px")},E.duration);
A(".jFlowControl").eq(F).addClass("jFlowSelected")});

A(".jFlowNext").click(function(){
if(F<B-1){
	F++		
}
A(".jFlowControl").removeClass("jFlowSelected");
A(E.slides).animate({marginLeft:"-"+(F*A(E.slides).find(":first-child").width()+"px")},E.duration);
A(".jFlowControl").eq(F).addClass("jFlowSelected")})};

A.fn.jFlow.defaults={easing:"swing",duration:400,width:"100%"}})(jQuery);