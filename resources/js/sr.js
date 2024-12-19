function sign(data) {
    var appKey = "fuseApp", appSecret = "fuseapp123456", salt = "fuse";
    data = JSON.stringify(data).replace(/{/g, "").replace(/}/g, "").replace(/,/g, "").replace(/\[/g, "").replace(/\]/g, "").replace(/:/g, "").replace(/'/g, "").replace(/'/g, "").replace(/"/g, "").replace(/"/g, "").replace(/\ +/g, "").replace(/[\r\n]/g, "");
    data = data.toLocaleUpperCase().split("").sort().join("");
    data = appKey + md5(appSecret) + salt + data;
    return md5(data).toLocaleUpperCase();
}

var data = {},
	datas = {},
	isFromCallPage = false,
	btn_reSend = $('#opt_morefirst'),sendCount=0,
	sendLoading=$('#sendLoading'),
	inst = new mdui.Dialog("#info_dialog", {
	    history: false,
	}),
	sendThird_dialog = new mdui.Dialog("#sendThird_dialog", {
	    history: false,
		modal:true,
	}),
	sendForth_dialog = new mdui.Dialog("#sendForth_dialog", {
	    history: false,
		modal:true,
	});
	confirm_dialog = new mdui.Dialog("#confirm_dialog", {
	    history: false,
		modal:true,
	});
if (location.search && location.search.slice(1)) {
	if (location.search.slice(1).indexOf('=') !== -1) {
		var url = location.search; //获取url中"?"符后的字串
		if (url.indexOf("?") != -1) {
			var str = url.substr(1);
			var strs = str.split("&");
			for (var i = 0; i < strs.length; i++) {
				data[strs[i].split("=")[0]] = strs[i].split("=")[1];
			}
		}

	}
}

if (sessionStorage.getItem('languageInfo')) {
	data['l'] = JSON.parse(sessionStorage.getItem('languageInfo')).info;

} else {
	data['l'] = 'id_ID';
}

if (sessionStorage.getItem('isFromCallPage')) {
	isFromCallPage = true;
	$('#errorMsg_code').html(data.l=='id_ID'?"<span class='tocallPage'>Klik di sini untuk mendapatkan kode verifikasi suara lagi.</span>":"<span class='tocallPage'>Click here to get voice verification code again.</span>")
	sessionStorage.removeItem("isFromCallPage");
}

if (sessionStorage.getItem('MobileInfo')) {
	var m = JSON.parse(sessionStorage.getItem('MobileInfo')).m || '';
	$('.mphone').val(m.replace(/(^\s*)|(\s*$)/g, ""));
	$('.mobileNum_dialog').html(m.replace(/(^\s*)|(\s*$)/g, ""));
	sendCount = JSON.parse(sessionStorage.getItem('MobileInfo')).sendCount || 0;
	if(sendCount>0){
		btn_reSend.show();
		$("#otp_btn").html(btn_reSend);
	}

	sessionStorage.removeItem("MobileInfo");
}

// $(window).on('beforeunload',function(e){//刷新
// 	sessionStorage.removeItem("MobileInfo");
// // 	sessionStorage.removeItem("languageInfo");
// 	sessionStorage.removeItem("isFromCallPage"); 
// });

$.ajax({
	url: '/insurance-finance-pre-service/pre/agent/clickNewRegister',
	type: 'POST',
	dataType: 'json',
	contentType: "application/json",
	data: jQuery.param({
		languageType:data.l ? data.l : 'id_ID',
		referralCode:data.r,
		f:data.f||'',
		d:data.d||'',
	}),
});

function IsPC() {
	var userAgentInfo = navigator.userAgent;
	var Agents = ["Android", "iPhone", "SymbianOS", "Windows Phone", "iPad", "iPod"];
	var flag = true;
	for (var v = 0; v < Agents.length; v++) {
		if (userAgentInfo.indexOf(Agents[v]) > 0) {
			flag = false;
			break;
		}
	}
	return flag;
}

function judgeSystem() {
	var u = navigator.userAgent,
		app = navigator.appVersion;
	var isAndroid = u.indexOf('Android') > -1 || u.indexOf('Linux') > -1; //g
	var isIOS = !!u.match(/\(i[^;]+;( U;)? CPU.+Mac OS X/); //ios终端

	if (isAndroid) {
		return 'ANDROID';
	}
	if (isIOS) {
		return 'IOS';
	}
	if (IsPC) {
		return 'PC';
	}
	return '';
}
var randNum = Math.random().toString(36).substr(2);
$.ajax({
	url: '/fuse-log/operlog/log',
	type: 'POST',
	dataType: 'json',
	contentType: "application/json;charset=utf-8",
	headers: {
		platform: 5,
		random: randNum,
		logSign: md5('Fuse0001' + randNum),
	},
	data: JSON.stringify({
		// ip:returnCitySN ? returnCitySN['cip'] : '',
		ip: '',
		fuseType: 5,
		model: judgeSystem(),
		operList: [{
			btnName: 'link_register',
			btnPage: location.href,
			noted: data.r,
			operTime: new Date().getTime(),
			operType: 6,
		}]
	}),
});

function setHelpContact(){
	var textContent = data.l=='en_US'?'Hi, My mobile number has been registered as a partner, please help me.':'Halo, nomor handphone saya terdaftar sebagai partner, mohon bantuannya.';

	$('#sendWhatsapp').attr('href','https://api.whatsapp.com/send?phone=6281181226888&text='.concat(encodeURIComponent(textContent)));
	$('#sendEmail').attr('href','mailto:cs@fuse.co.id?body='.concat(encodeURIComponent(textContent)));

	if (sessionStorage.getItem('isFromCallPage')) {
		isFromCallPage = true;
		$('#errorMsg_code').html(data.l=='id_ID'?"<span class='tocallPage'>Klik di sini untuk mendapatkan kode verifikasi suara lagi.</span>":"<span class='tocallPage'>Click here to get voice verification code again.</span>")
	}
}
// if (location.search && location.search.slice(1)) {
//     if (location.search.slice(1).indexOf('=') !== -1) {
data['invitationCode'] = data.r;
datas['invitationCode'] = data['invitationCode'];
//$('#referral').val(data.r);
//     }
// }

if(data.l=='en_US'){
	$('#selectVal').removeClass('language_ID');
	$('#selectVal').addClass('language_EN');
	$('.l_id').hide();
	$('.l_en').show();
}else{
	$('#selectVal').removeClass('language_EN');
	$('#selectVal').addClass('language_ID');
	$('.l_en').hide();
	$('.l_id').show();
}
setHelpContact();

datas['language'] = data.l ? data.l : 'id_ID';
data['language'] = data.l ? data.l : 'id_ID';

$('#selectVal').on('click',function(){
	$('.errorMsg').html('');

	if(data.l == 'en_US'){
		data.l = data.language = datas.language = 'id_ID';
		$('#selectVal').removeClass('language_EN');
		$('#selectVal').addClass('language_ID');
		$('.l_en').hide();
		$('.l_id').show();
	}else{
		data.l = data.language = datas.language = 'en_US';
		$('#selectVal').removeClass('language_ID');
		$('#selectVal').addClass('language_EN');
		$('.l_id').hide();
		$('.l_en').show();
	}
	var otp = data.l == 'id_ID'?$("#vCode_id").val().replace(/(^\s*)|(\s*$)/g, ""):$("#vCode_en").val().replace(/(^\s*)|(\s*$)/g, "");
	if($('#errorMsg_code').is(":visible") && $('#callTips').is(":hidden") && $('#tips').is(":hidden") && sendCount>0)
		checkCode(otp);
	setHelpContact();
	$(".tocallPage").unbind("click");
	$('.tocallPage').on('click',toCallPage);
});

$('#eyesBtn').on('click',function(){
	if($('#eyesBtn img').eq(0).is(':visible')){
		$('#eyesBtn img').eq(0).hide();
		$('#eyesBtn img').eq(1).show();
		$('#password_en').attr('type','text');
		$('#password_id').attr('type','text');
		return
	}
	$('#eyesBtn img').eq(1).hide();
	$('#eyesBtn img').eq(0).show();
	$('#password_en').attr('type','password');
	$('#password_id').attr('type','password');
});

$("#mobile_id").on('change',function(){
	$("#mobile_en").val($("#mobile_id").val());
});
$("#mobile_en").on('change',function(){
	$("#mobile_id").val($("#mobile_en").val());
});
$("#vCode_id").on('change',function(){
	$("#vCode_en").val($("#vCode_id").val());
});
$("#vCode_en").on('change',function(){
	$("#vCode_id").val($("#vCode_en").val());
});
$("#password_id").on('change',function(){
	$("#password_en").val($("#password_id").val());
});
$("#password_en").on('change',function(){
	$("#password_id").val($("#password_en").val());
});
$("#name_id").on('change',function(){
	$("#name_en").val($("#name_id").val());
});
$("#name_en").on('change',function(){
	$("#name_id").val($("#name_en").val());
});


//判断此代理是否能进行分享注册
jQuery.ajax({
	url: '/insurance-finance-pre-service/pre/agent/getAgentInfo',
	type: 'GET',
	dataType: 'json',
	data: jQuery.param(data),
	complete: function(xhr, textstatus) {},
	success: function(data, textStatus, xhr) {
		if (data.status == 1) {
			$('#register').show();
			$('#loading').hide();
		} else if (data.status == 0) {
			sessionStorage.setItem("languageInfo", JSON.stringify({
				info: datas.language
			}));
			$('#register').hide();
			$('#register').html('');
			window.location.href = './notShareRegister.html?t=1&l=' + datas.language + 'r=' + data.r;
		} else{
			sessionStorage.setItem("languageInfo", JSON.stringify({
				info: datas.language
			}));
			window.location.href = './notShareRegister.html?t=1&l=' + datas.language + 'r=' + data.r;
		}
	},
	error: function(xhr, textStatus, errorThrown) {
		$('#loading').hide();
		mdui.snackbar({
			message: data.language == 'id_ID' ?
				"Kendala jaringan internet. Harap coba kembali nanti" : "network error, please try again later.",
			position: 'top'
		});
	}
});

// 是否展示account type
$.ajax({
	url: '/insurance-finance-vs-api/api/fuse/redirect/checkAccountJumpPage',
	type: 'POST',
	dataType: 'json',
	contentType: "application/json;charset=utf-8",
	data: JSON.stringify({
		referralCode: data.r
	}),
	success: function(res, textStatus, xhr) {
		if(!res.errorCode){
			if(res.resultObj.dealershipType == 1){
				$('#accountType').show();
				var personType = localStorage.getItem('personType')
				if(personType == 1) {
					$('.corporate-con').hide()
					$('.personal-con').show()
				} else if(personType == 2) {
					$('.corporate-con').show()
					$('.personal-con').hide()
				}
			}else{
				$('#accountType').hide();
			}

			// check if param got public = 1 then hide the account type
			if(data.public == "1"){
				$('#accountType').hide();
			} else {
				$('#accountType').show();
			}

		}else{
			mdui.snackbar({
				message: res.errorCode,
				position: 'top'
			});
		}
		$('#loading').hide();
	},
	error: function(xhr, textStatus, errorThrown) {
		$('#loading').hide();
		mdui.snackbar({
			message: data.language == 'id_ID' ?
				"Kendala jaringan internet. Harap coba kembali nanti" : "network error, please try again later.",
			position: 'top'
		});
	}
});


$('#closeBtn').on('click',function(){
	inst.close();
})

$('input').on('touchstart',function(){
	$(this).attr('readonly',false);
});
$('body').on('touchend', function(el) {
	if(el.target.tagName != 'INPUT') {
		$('input').blur()
	}
})

function checkMobile(phone) {
	var reg = /^[0-9]*$/;
	if (!phone) {
		// mdui.snackbar({
		//     message: data.language == 'id_ID' ? "Harap input nomor handphone" : "Please input mobile phone",
		//     position: 'top'
		// });
		$('#errorMsg_mobile').html(data.language == 'id_ID' ? "Masukkan nomor handphone." : "Please enter your mobile number.");
		return true;
	}
	// (phone.length < 9 || phone.length > 15)
	if (!reg.test(phone) || phone.length<9 || phone.length>12 || phone.charAt(0)!=8) {//首位必须以8开头;长度为9至12位（不包含62，从8开始计算）;必须为纯数字
		// mdui.snackbar({
		//     message: data.language == 'id_ID' ?
		//         "Harap input nomor handphone yang benar supaya kami dapat hubungi anda" : "Please input the correct phone number",
		//     position: 'top'
		// });
		$('#errorMsg_mobile').html(data.language == 'id_ID' ? "Maaf, nomor handphone salah. Silakan periksa kembali." : "Sorry, this mobile number is invalid. Please check it.");
		return true;
	}
	return false;
}

function checkPassword(password) {
	var reg = /[\x00-\xff]+/g
	if (!password) {
		// mdui.snackbar({
		//     message: data.l == 'id_ID' ? 'Harap Input Kata Sandi' : 'Please input password',
		//     position: 'top'
		// });
		$('#tips_password').hide();
		$('#errorMsg_password').html(data.language == 'id_ID' ? "Silakan buat kata sandi untuk akun anda." : "Please set a password for your account.");
		return true
	}
	if (!reg.test(password) || (password+'').indexOf(' ')!=-1) {//只能为数字、大小写字母和特殊字符，不支持空格。
		$('#tips_password').hide();
		$('#errorMsg_password').html(data.language == 'id_ID' ? "Maaf, hanya huruf, angka dan karakter spesial (kecuali spasi) yang diperbolehkan." : "Sorry, only letters, numbers, and special characters(except spaces) are allowed.");
		return true;
	}
	if (password.length < 6) {
		// mdui.snackbar({
		//     message: data.l == 'id_ID' ? 'Kata sandi minimal 6 digit' : 'Password is at least 6 digits',
		//     position: 'top'
		// });
		$('#tips_password').hide();
		$('#errorMsg_password').html(data.language == 'id_ID' ? "Masukkan kata sandi minimal 6 karakter." : " Please set a password with at least 6 characters.");
		return true;
	}
	return false;
}

function checkCode(vCode,isShowCall) {
	var reg = /^[0-9]*$/;
	if (!vCode || (vCode.length!=4 && vCode.length!=6) || !reg.test(vCode)) {
		// mdui.snackbar({
		//     message: data.l == 'id_ID' ? 'Masukkan 6 angka kode verifikasi yang diterima handphone anda' : 'Please input the 6 digits verification code received on your phone',
		//     position: 'top'
		// });
		$('#tips').hide();
		$('#callTips').hide();
		$('#errorMsg_code').html('');
		if(isShowCall && !vCode)
			$('#callTips').show();
		else
			$('#errorMsg_code').html(data.language == 'id_ID' ? "Kode verifikasi adalah 4 angka. <span class='tocallPage'>Klik di sini untuk mendapatkan kode verifikasi suara.</span>" : "The verification code should be 4 digits. <span class='tocallPage'>Click here to get voice verification code.</span>");
		// 	$('#errorMsg_code').html(data.language == 'id_ID' ? "Masukkan 6 angka kode yang dikirimkan ke nomor anda dengan SMS." : "Please enter the 6-digit code we sent to your mobile number by SMS.");
		$(".tocallPage").unbind("click");
		$('.tocallPage').on('click',toCallPage);
		return true
	}
	// if(!reg.test(vCode)){//必须为纯数字
	// 	$('#tips').hide();
	// 	$('#callTips').hide();
	// 	// if(!isShowCall)
	// 		$('#errorMsg_code').html(data.language == 'id_ID' ? "Kode verifikasi salah. <span class='tocallPage'>Klik di sini untuk mendapatkan kode verifikasi suara.</span>" : "Verification code errors. <span class='tocallPage'>Click here to get voice verification code.</span>");
	// 		// $('#errorMsg_code').html(data.language == 'id_ID' ? "Kode SMS harus 6 angka." : "The SMS code should be a 6-digit number.");
	// 	$(".tocallPage").unbind("click");
	// 	$('.tocallPage').on('click',toCallPage);
	// 	return true
	// }
	return false;
}

function checkName(name) {
	name = name.replace(/(^\s*)|(\s*$)/g, "").toLocaleLowerCase();
	var reg = /^[a-zA-Z\d_\s]*$/,//只能为大小写字母、数字、下划线和空格
			firstChartReg = /^[a-zA-Z]$/;//第一位必须是字母
	if (!name) {
		$('#errorMsg_nickName').html(data.language== 'id_ID' ? 'Masukkan Nama panggilan.' : 'Please enter your nickname.');
		return true
	}
	name += '';
	if (new RegExp("^test.*$").test(name) || new RegExp("^.*test$").test(name) || !reg.test(name) || name.length<1 || !firstChartReg.test(name.charAt(0))) {
		$('#errorMsg_nickName').html(data.language == 'id_ID' ?'Maaf, nama panggilan harus dimulai dengan huruf dan bisa digabungkan dengan angka, garis bawah dan spasi.' : 'Sorry, the nickname should begin with letters, and can be combined with numbers, underscores, and spaces.');
		return true
	}
	return false
}

// 邮箱检测
function checkEmail(email) {
	const reg = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/

	if(!email){
		$('#errorMsg_email').html(data.language == 'id_ID' ? 'Masukkan Email' : 'Please enter your Email');
		return true
	}
	if (!reg.test(email)) {
		$('#errorMsg_email').html(data.language == 'id_ID' ? 'Invaild Format' : 'Invaild Format');
		return true
	}

	return false
}


//验证码发送
$("#otp_btn").on('click', function(event) {
	event.preventDefault();
	if ($("#otp_btn")[0].disabled) {
		return
	}
	$('.errorMsg').html('');
	$('#callTips').hide();
	handleSendCode();

});
$('input').bind("input propertychange",function(){
	if($(this).attr('class') && $(this).attr('class').indexOf('mphone')!=-1){//电话号码
		if($(this).val().length>0){
			$("#otp_btn").attr('disabled',false);
		}else{
			$("#otp_btn").attr('disabled',true);
		}
	}
	if($(this).val().length>0){
		if($(this).siblings('.clearIcon').attr('class') && $(this).siblings('.clearIcon').attr('class').indexOf('codeClear')!=-1){
			if(sendCount>0){
				$(this).siblings('.clearIcon').css('right','110px')
			}else{
				$(this).siblings('.clearIcon').css('right','70px')
			}
		}
		$(this).siblings('.clearIcon').show();
	}else{
		$(this).siblings('.clearIcon').hide();
	}
})
$('.clearIcon').on('click',function(){
	if($(this).siblings('input').attr('class').indexOf('mphone')!=-1){//电话号码
		$("#otp_btn").attr('disabled',true);
	}
	$(this).siblings('input').val('');
	$(this).hide();
})

function handleSendCode(isThird  = false) {
  // console.log('handleSendCode', grecaptcha)
  grecaptcha.ready(function() {
    grecaptcha.execute(reCaptchaSiteKey, {action: 'submit'}).then(function(token) {
        // Add your logic to submit to your backend server here.
        // console.log('Add your logic to submit to your backend server here', token)
        sendCode(isThird, token)
    }, (error) => {
      console.log('grecaptcha.execute', error)
      sendCode(isThird, '')
    });
  });
}

function getreCaptchaToken(isThird  = false) {
  console.log('getreCaptchaToken', getreCaptchaToken)
  grecaptcha.ready(function() {
    grecaptcha.execute(reCaptchaSiteKey, {action: 'submit'}).then(function(token) {
        return token;
    }, (error) => {
      console.log('grecaptcha.execute', error)
      return ''
    });
  });
}


function sendCode(isThird = false, recaptchaToken = ''){
  // console.log('sendCode', firebaseApp.recaptchaToken)
  // 第一次调用没有人机识别toten
	// if(!firebaseApp.recaptchaToken) return

	var mobile = data.language == 'id_ID'?$("#mobile_id").val().replace(/(^\s*)|(\s*$)/g, ""):$("#mobile_en").val().replace(/(^\s*)|(\s*$)/g, ""),
		seconds = 60;
	var otp = data.language == 'id_ID'?$("#vCode_id").val().replace(/(^\s*)|(\s*$)/g, ""):$("#vCode_en").val().replace(/(^\s*)|(\s*$)/g, "");
	if (checkMobile(mobile)) {
		return;
	}

	// $('.mobileNum').html(mobile.slice(0,1)+'****'+mobile.slice(-3));
	$('.mobileNum').html(mobile);
	$('.mobileNum_dialog').html(mobile);

	if(!isThird){
		sendCount++;
	}
	if(sendCount==3&&!isThird){
		sendCount-=1;
		checkCode(otp,true);
		sendThird_dialog.open();
		return
	}
	if(sendCount==4&&!isThird){
		sendForth_dialog.open();
		return
	}
	if(sendCount>1){
		$('#otp_btn').append(sendLoading);
	}
	$("#opt_first").hide();
	btn_reSend.hide();
	$("#sendLoading").show();
	$("#otp_btn").attr('disabled', true);

	$.ajax({
		url: '/fuse-log/operlog/log',
		type: 'POST',
		dataType: 'json',
		contentType: "application/json;charset=utf-8",
		cache:false,
		headers: {
			platform: 5,
			random: randNum,
			logSign: md5('Fuse0001' + randNum),
		},
		data: JSON.stringify({
			// ip:returnCitySN ? returnCitySN['cip'] : '',
			ip: '',
			fuseType: 5,
			model: judgeSystem(),
			accountId: ('62' + (mobile.replace(/\s/g, ""))).replace(
				/^(62062|62620|6262|620|62\\+620|62\\+62)/, "62"),
			operList: [{
				btnName: 'btn_sendCode',
				btnPage: location.href,
				noted: data.r,
				operTime: new Date().getTime(),
				operType: 2,
			}]
		}),
	});

  var j = {
    "mobile": mobile.replace(/^0/,''),
    "languageType": data.l ? data.l : 'id_ID',
    invitationCode:data.r
  };
  if(recaptchaToken) {
    j.recaptchaToken = recaptchaToken
  }

  jQuery.ajax({
    url: '/insurance-finance-pre-service/pre/v2/agent/newVerificationCode',
    type: 'GET',
    dataType: 'json',
    cache:false,
    // contentType: "application/json;charset=utf-8",
    data: jQuery.param(j),
    headers: {
      'sign': sign(j)
    },
    complete: function(xhr, textstatus) {},
    success: function(data, textStatus, xhr) {
      if((data.status+'') == 0){//send success
        if((sendCount==3  && isThird) || (sendCount ==4 && isThird) || sendCount<3 || sendCount>4)
          $('#tips').show();

        var timers = setInterval(function() {
          seconds--;
          if (seconds <= 0) {
            $("#otp_btn").removeClass('sendBtn_sending');
            $("#otp_btn").attr('disabled', false);
            btn_reSend.show();
            $("#otp_btn").html(btn_reSend);
            clearInterval(timers);

            // if(sendCount==1 && checkCode(otp,true)){
            if(checkCode(otp,true)){
              $('#tips').hide();
              // $('#callTips').show();
            }
            return
          }
          $("#otp_btn").attr('disabled', true);
          $("#otp_btn").addClass('sendBtn_sending');
          $("#otp_btn").html(seconds + 's');

        }, 1000);
      }
      if((data.status+'') != 0){
        if(sendCount>0)
          sendCount--;
        $("#otp_btn").attr('disabled', false);
        $("#sendLoading").hide();
        if(sendCount>0){
          $("#opt_first").hide();
          btn_reSend.show();
        }else{
          btn_reSend.hide();
          $("#opt_first").show();
        }
        if(data.status == 2){
          inst.open();
          return
        }
        mdui.snackbar({
          message: data.msg,
          position: 'top'
        });
      }
    },
    error: function() {
      if(sendCount>0)
        sendCount--;
      $("#otp_btn").attr('disabled', false);
      $("#sendLoading").hide();
      if(sendCount>0){
        $("#opt_first").hide();
        btn_reSend.show();
      }else{
        btn_reSend.hide();
        $("#opt_first").show();

      }
      mdui.snackbar({
        message: data.language == 'id_ID' ?
          "Kendala jaringan internet. Harap coba kembali nanti" : "network error, please try again later.",
        position: 'top'
      });
    }
  });
}

$('#sendThird_dialog')[0].addEventListener('confirm.mdui.dialog', function () {
  sendCount+=1;
  $('.errorMsg').html('');
  $('#callTips').hide();
  handleSendCode(true);
});

$('#closeBtn_sendForth').on('click', function () {
  handleSendCode(true);
});

function toCallPage(){//打电话
	//接口
	var m = (data.language == 'id_ID'?$("#mobile_id").val().replace(/(^\s*)|(\s*$)/g, ""):$("#mobile_en").val().replace(/(^\s*)|(\s*$)/g, "")),
		sendData = {
			mobile:m.replace(/^0/,''),
			language:data.language
		}
	if (checkMobile(m)) {
		return;
	}
	$('#loading').show();

	$.ajax({
		url: '/insurance-finance-vs-api/api/fuse/send/verificationCodeForVoice',
		type: 'POST',
		dataType: 'json',
		contentType: "application/json;charset=utf-8",
		data: JSON.stringify(sendData),
		headers: {
			'sign': sign(sendData)
		},
		success: function(res, textStatus, xhr) {
			if(!res.errorCode){
				sessionStorage.setItem("languageInfo", JSON.stringify({
					info: datas.language
				}));
				sessionStorage.setItem("MobileInfo", JSON.stringify({
					m:m,
					sendCount:sendCount,
					link:location.href,
				}));
				window.location.href = './callPage.html?l='+data.language+'&m='+m+'&c='+sendCount;
			}else{
				if(res.errorCode==54){//电话号码已存在
					inst.open();
					$('#loading').hide();
					return
				}
				mdui.snackbar({
					message: res.errorCode,
					position: 'top'
				});
			}
			$('#loading').hide();
		},
		error: function(xhr, textStatus, errorThrown) {
			$('#loading').hide();
			mdui.snackbar({
				message: data.language == 'id_ID' ?
					"Kendala jaringan internet. Harap coba kembali nanti" : "network error, please try again later.",
				position: 'top'
			});
		}
	});

}
$('#sendForth_dialog')[0].addEventListener('confirm.mdui.dialog', toCallPage);

$(".tocallPage").unbind("click");
$('.tocallPage').on('click',toCallPage);


if(!localStorage.getItem('personType')) {
	localStorage.setItem('personType', 1)
}

// 监听 account type 按钮点击 change
$('input[type="radio"]').on('change',function(e){
	const _type = $(e.currentTarget).attr('data-id')
	if(_type==1){
		$('.atypeTxt').eq(0).html('Akun atas nama perorangan')
		$('.atypeTxt').eq(1).html('Account on behalf of individu')
		$('.corporate-con').hide()
		$('.personal-con').show()
	} else {
		$('.atypeTxt').eq(0).html('Akun atas nama perusahaan')
		$('.atypeTxt').eq(1).html('Account on behalf of corporate')
		$('.corporate-con').show()
		$('.personal-con').hide()
	}
	localStorage.setItem('personType', _type)
})

$("#reg").on('click', function(event) {
	event.preventDefault();
	var personType = $('input[type="radio"]')[0].checked ? 1 : 2

	if($('#accountType').css('display') == 'none') {
		if(personType == 1) {
			if(data.public == "1") {
				submitInfo(1);
			} else {
				submitInfo();
			}
		} else if (personType == 2) {
			handlePersonType2Submit()
		}
		return
	}
	if(personType == 1) {
		submitInfo(1)
	} else if (personType == 2) {
		handlePersonType2Submit(1)
	}
});
$('#registerSubmit').on('click',function(event){
	event.preventDefault();
	var personType = $('input[type="radio"]')[0].checked ? 1 : 2
	if(personType == 1) {
		submitInfo();
	} else if (personType == 2) {
		handlePersonType2Submit()
	}
});

function submitInfo(isCheck){
	$('.errorMsg').html('');
	var mobile = data.language == 'id_ID'?$("#mobile_id").val().replace(/(^\s*)|(\s*$)/g, ""):$("#mobile_en").val().replace(/(^\s*)|(\s*$)/g, ""),
		otp = data.language == 'id_ID'?$("#vCode_id").val().replace(/(^\s*)|(\s*$)/g, ""):$("#vCode_en").val().replace(/(^\s*)|(\s*$)/g, ""),
		password = data.language == 'id_ID'?$("#password_id").val().replace(/(^\s*)|(\s*$)/g, ""):$("#password_en").val().replace(/(^\s*)|(\s*$)/g, ""),
		name = data.language == 'id_ID'?$("#name_id").val().replace(/(^\s*)|(\s*$)/g, ""):$("#name_en").val().replace(/(^\s*)|(\s*$)/g, ""),
		email = data.language == 'id_ID'?$("#email_id").val().replace(/(^\s*)|(\s*$)/g, ""):$("#email_en").val().replace(/(^\s*)|(\s*$)/g, ""),
		next = false;

	if (checkMobile(mobile)) {
		next=true;
	}
	if (checkCode(otp)) {
		next=true;
	}
	if(checkEmail(email)) {
		next = true
	}
	if (checkPassword(password)) {
		next=true;
	}
	if(checkName(name)){
		next=true;
	}

	if (next) {
		return;
	}

	if(isCheck){
		if(data.l == 'id_ID') {
			if($('input[type="radio"]')[0].checked) {
				$('#confirmTxt').html('Apa Anda yakin ingin mendaftar sebagai akun individu? Anda perlu KTP sebagai identitas utama Anda nanti.')
			}else{
				$('#confirmTxt').html('Apa Anda yakin ingin mendaftar sebagai akun perusahaan?')
			}
		} else{
			if($('input[type="radio"]')[0].checked) {
				$('#confirmTxt').html('Are you sure to register as an individual account? You will need a KTP as your main identity later.')
			}else{
				$('#confirmTxt').html('Are you sure to register as a corporate account?')
			}
		}
		confirm_dialog.open()
		return
	}

	$('#loading').show();
	confirm_dialog.close();
	$.ajax({
		url: '/fuse-log/operlog/log',
		type: 'POST',
		dataType: 'json',
		contentType: "application/json;charset=utf-8",
		headers: {
			platform: 5,
			random: randNum,
			logSign: md5('Fuse0001' + randNum),
		},
		data: JSON.stringify({
			// ip:returnCitySN ? returnCitySN['cip'] : '',
			ip: '',
			fuseType: 5,
			model: judgeSystem(),
			accountId: ('62' + (mobile.replace(/\s/g, ""))).replace(
				/^(62062|62620|6262|620|62\\+620|62\\+62)/, "62"),
			accountName:name,
			operList: [{
				btnName: 'btn_register',
				btnPage: location.href,
				thisPage:otp,
				noted: data.r,
				operTime: new Date().getTime(),
				operType: 2,
			}]
		}),
	});
	var isPublic = data.public;
	var j = {
		"mobile": mobile.replace(/^0/,''),
		"password": password,
		"invitationCode": data.r,
		"verificationCode": otp,
		"languageType": data.l ? data.l : 'id_ID',
		"customerName":name,
		email,
		'f':data.f||'',
		'd':data.d||'',
	};
	if($('#accountType').css('display') != 'none'){
		j['personType'] = $('input[type="radio"]')[0].checked ? 1 : 2
	}
	jQuery.ajax({
		url: '/insurance-finance-pre-service/pre/v2/agent/newCreateAgent',
		type: 'POST',
		dataType: 'json',
		contentType: "application/json;charset=utf-8",
		data: JSON.stringify(j),
		headers: {
			'sign': sign(j)
		},
		complete: function(xhr, textstatus) {},
		success: function(data, textStatus, xhr) {
			$('#loading').hide();
			mobile = mobile.replace(/\s/g, "");
			mobile = '62' + mobile;
			mobile = mobile.replace(
				/^(62062|62620|6262|620|62\\+620|62\\+62)/, "62");
			if (data.status == 0) {
				sessionStorage.setItem("languageInfo", JSON.stringify({
					info: datas.language
				}));
				if(isPublic && isPublic == 1) {
					window.location.href = "./registerSuccess_newC.html?l=" +datas.language+'&m='+mobile;
				} else {
					if(data.activity == 'A'){
						window.location.href = "./registerSuccess_newA.html?l=" +datas.language+'&m='+mobile;
					}else{
						window.location.href = "./registerSuccess_newB.html?l=" +datas.language+'&m='+mobile+'&b='+data.amount;
					}
				}

			} else {
				mdui.snackbar({
					message: data.msg,
					position: 'top'
				});
			}

		},
		error: function(xhr, textStatus, errorThrown) {
			$('#loading').hide();
			mdui.snackbar({
				message: data.language == 'id_ID' ?
					"Kendala jaringan internet. Harap coba kembali nanti" : "network error, please try again later.",
				position: 'top'
			});
		}
	});

}

const topH = $('#topContent').height()
$('#topBox').height(topH + 56)
$('#register').css('top', topH + 10)

var oriObj = {corporateUploadQOList: []};
function handlePersonType2Submit(isCheck) {
	if(!handlePersonType2CanNext(oriObj)) {
		return
	}
	var info = {
		companyName: oriObj.companyName,
		corporateUploadQOList: oriObj.corporateUploadQOList, // attachmentType 从1开始, 0位置没有赋值
		email: oriObj.email,
		inviteCode: data.r,
		referenceCode: data.k,
		languageType: data.l ? data.l : 'id_ID',
		mobile: oriObj.mobile.replace(/^0/,''),
		name: oriObj.name,
	};
	if(isCheck){
		if(data.l == 'id_ID') {
			if($('input[type="radio"]')[0].checked) {
				$('#confirmTxt').html('Apa Anda yakin ingin mendaftar sebagai akun individu? Anda perlu KTP sebagai identitas utama Anda nanti.')
			}else{
				$('#confirmTxt').html('Apa Anda yakin ingin mendaftar sebagai akun perusahaan?')
			}
		} else{
			if($('input[type="radio"]')[0].checked) {
				$('#confirmTxt').html('Are you sure to register as an individual account? You will need a KTP as your main identity later.')
			}else{
				$('#confirmTxt').html('Are you sure to register as a corporate account?')
			}
		}
		confirm_dialog.open()
		return
	}

	$('#loading').show();
	confirm_dialog.close();
	$.ajax({
		url: '/fuse-log/operlog/log',
		type: 'POST',
		dataType: 'json',
		contentType: "application/json;charset=utf-8",
		headers: {
			platform: 5,
			random: randNum,
			logSign: md5('Fuse0001' + randNum),
		},
		data: JSON.stringify({
			// ip:returnCitySN ? returnCitySN['cip'] : '',
			ip: '',
			fuseType: 5,
			model: judgeSystem(),
			accountId: ('62' + (oriObj.mobile.replace(/\s/g, ""))).replace(
				/^(62062|62620|6262|620|62\\+620|62\\+62)/, "62"),
			accountName: info.name,
			operList: [{
				btnName: 'btn_register',
				btnPage: location.href,
				thisPage: info.otp,
				noted: data.r,
				operTime: new Date().getTime(),
				operType: 2,
			}]
		}),
	});
	if($('#accountType').css('display') != 'none'){
		info['personType'] = $('input[type="radio"]')[0].checked ? 1 : 2
	}
	jQuery.ajax({
		url: '/insurance-finance-vs-api/api/fuse/corporate/register',
		type: 'POST',
		dataType: 'json',
		contentType: "application/json;charset=utf-8",
		data: JSON.stringify(info),
		headers: {
			'sign': sign(info)
		},
		complete: function(xhr, textstatus) {},
		success: function(data, textStatus, xhr) {
			$('#loading').hide();
			var mobile = oriObj.mobile.replace(/\s/g, "");
			mobile = '62' + mobile;
			mobile = mobile.replace(
				/^(62062|62620|6262|620|62\\+620|62\\+62)/, "62");

			// var resObj = JSON.parse(data)
			var resObj = data
			console.log('success', data, resObj)
			if (resObj.code == 200) {
				sessionStorage.setItem("languageInfo", JSON.stringify({
					info: datas.language
				}));
				window.location.href = "./registerSuccess_cooper_newA.html?l=" +datas.language+'&m='+mobile;
				// if(resObj.data.activity == 'A'){
				// 	window.location.href = "./registerSuccess_cooper_newA.html?l=" +datas.language+'&m='+mobile;
				// }else{
				// 	window.location.href = "./registerSuccess_newB.html?l=" +datas.language+'&m='+mobile+'&b=' + resObj.data.amount;
				// }

			} else {
				mdui.snackbar({
					message: data.message,
					position: 'top'
				});
			}

		},
		error: function(xhr, textStatus, errorThrown) {
			$('#loading').hide();
			mdui.snackbar({
				message: data.language == 'id_ID' ?
					"Kendala jaringan internet. Harap coba kembali nanti" : "network error, please try again later.",
				position: 'top'
			});
		}
	});
}

// 选择公司形式注册时, 校验公司相关必填数据
function handlePersonType2CanNext(info) {
	var operaKeys = ['companyName', 'personinChargeName', 'personInChargePhoneNumber', 'companyEmail'],
			canNext = true;
	operaKeys.forEach(function(key) {
		var val = getVal(key)
		var labelName = ''
		if(key == 'companyName') {
			info.companyName = val
			labelName = data.language == 'id_ID' ? "Masukkan nama perusahaan" : "Please enter your company name."
		} else if(key == 'personinChargeName') {
			info.name = val
			labelName = data.language == 'id_ID' ? "Masukkan nama person in charge" : "Please enter your person in charge name"
		} else if (key == 'personInChargePhoneNumber') {
			info.mobile = val
			labelName = data.language == 'id_ID' ? "Masukkan nomor person in charge." : "Please enter your person in charge phone number."
		} else if (key == 'companyEmail') {
			info.email = val
			labelName = data.language == 'id_ID' ? "Masukkan email perusahaan." : "Please enter your company email."
		}
		if(!checkinputVal(val, key, labelName)) {
			canNext = false
		}
	})

	// check is all file uploaded 
	if(info.corporateUploadQOList.length !== 5) {
		// check upload files is it all got documents?
		var countUpload = 0
		var totalUpload = 5
		for (let i = 0; i < totalUpload; i++) {
			var no = i + 1
		  if (info.corporateUploadQOList[i]) {
			$('#fileUploadedMsg_upload' + no ).html('') // File uploaded
			countUpload += 1
		  } else {
			$('#fileUploadedMsg_upload' + no).html(getUploadMsg(no)) // Empty file, show error
		  }
		}

		// block the submission all the file not uploaded
		if (countUpload !== totalUpload) {
			canNext = false
		}
	}
	return canNext
}

function getUploadMsg(type) {
	switch(type) {
		case 1: 
			return data.language == 'id_ID' ? 'Silahkan unggah naik anggaran dasar perusahaan.' : 'Please upload Company Article of Association'
		case 2: 
			return data.language == 'id_ID' ? 'Silahkan unggah naik dokumen perizinan perusahaan.' : 'Please upload Company permission document'
		case 3: 
			return data.language == 'id_ID' ? 'Silahkan unggah naik KTP PIC/ Direktur perusahaan.' : 'Please upload PIC or Director KTP'
		case 4: 
			return data.language == 'id_ID' ? 'Silahkan unggah naik npwp perusahaan.' : 'Please upload company tax document'
		case 5: 
			return data.language == 'id_ID' ? 'Silahkan unggah POA/Surat kuasa.' : 'Please upload power of attorney'
		default:
			return ''
	}
}

// 获取输入框的值
function getVal(key) {
	var idVal = $(`#${key}_id`).val().replace(/(^\s*)|(\s*$)/g, ""),
			enVal = $(`#${key}_en`).val().replace(/(^\s*)|(\s*$)/g, "")
	return data.language == 'id_ID' ? idVal : enVal
}

// 校验输入框的值
function checkinputVal(val, key, labelName) {
	var isId_ID = data.language == 'id_ID' ? 'id' : 'en'
	var suffix = isId_ID ? 'id' : 'en'
	var res = val && val.trim()
	var canGo = true
	if(key == 'companyEmail') {
		canGo = checkCompanyEmail(true, res)
	}
	if(key == 'personInChargePhoneNumber') {
		canGo = checkPersonInChargePhoneNumber(true, res)
	}
	if(!res) {
		$(`#errorMsg_${key}`).html(labelName);
		canGo = false
	}
	if(!canGo) {
		$(`#${key}_${suffix}`).css("border-color","#D90109")
	} else {
		$(`#${key}_${suffix}`).css("border-color","#909090")
		$(`#errorMsg_${key}`).html('');
	}
	return canGo
}

// 校验手机号码格式
function checkPersonInChargePhoneNumber(canGo, res) {
	var phoneReg = /^[0-9]*$/;
	if (!res) {
		$('#errorMsg_personInChargePhoneNumber').html(data.language == 'id_ID' ? "Masukkan nomor handphone." : "Please enter your mobile number.");
		canGo = false
	}
	if (!phoneReg.test(res) || res.length<9 || res.length>12 || res.charAt(0)!=8) {//首位必须以8开头;长度为9至12位（不包含62，从8开始计算）;必须为纯数字
		$('#errorMsg_personInChargePhoneNumber').html(data.language == 'id_ID' ? "Maaf, nomor handphone salah. Silakan periksa kembali." : "Sorry, this mobile number is invalid. Please check it.");
		canGo = false
	}
	return canGo
}

// 校验 email 格式
function checkCompanyEmail(canGo, res) {
	var emailReg = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
	if(!res){
		$('#errorMsg_companyEmail').html(data.language == 'id_ID' ? 'Masukkan Email' : 'Please enter your Email');
		canGo = false
	}
	if (!emailReg.test(res)) {
		$('#errorMsg_companyEmail').html(data.language == 'id_ID' ? 'Invaild Format' : 'Invaild Format');
		canGo = false
	}
	return canGo
}
$('.sec-tit').on('click', function() {
	$('.arrow').toggleClass('toggle-show')
	$('.upload-con').toggleClass('upload-toggle')
})

$('.shadow').on('click', function(e) {
	var divId = $(e.currentTarget).attr('id')
	$(`#file_${divId}`).click()
	// console.log('click 上传', $(e.currentTarget).attr('id'))
})

// 文件上传
function handleFileUpload(obj, type) {
	$('#fileUploadedMsg_upload' + type ).html('')
	var htmlArr = ['', 'AD', 'Perizinan', 'KTP_PIC/Direktur', 'NPWP', 'Surat_Kuasa'],
			companyName = getVal('companyName'),
	    fileData = $(obj).prop("files")[0],
	    fileSize = fileData.size / 1024 / 1024,
			fileType = fileData.name.substring(fileData.name.lastIndexOf('.')+1).toLowerCase(),
			formData = new FormData(),
			message = '',
			isid_ID = data.language == 'id_ID';
	if(!companyName) {
		message = isid_ID ? "Silakan nama perusahaan lapangan dulu" : "please field company name first"
	}
	if(fileSize > 4) {
		message = isid_ID ? "Ukuran berkas tidak dapat melebihi 4M" : "File size cannot exceed 4M"
	}
	if(fileType != 'png' && fileType != 'jpeg' && fileType != 'pdf') {
		message = isid_ID ? "Silakan mengunggah berkas PDF, PNG dan JPEG" : "Please upload PDF, PNG and JPEG files"
	}
	if(!companyName || fileSize > 4 || (fileType != 'png' && fileType != 'jpeg' && fileType != 'pdf')) {
		$(`#file_d${type}`).val('')
		mdui.snackbar({ message, position: 'top' });
		return false
	}
	formData.append('files', fileData);
	formData.append('attachmentType', type)
	formData.append('companyName', companyName)
	formData.append('referenceCode', data.k)
	formData.append('inviteCode', data.r)
	// console.log('handleFileUpload', formData, fileData)

	$.ajax({
		url: "/insurance-finance-vs-api/api/fuse/corporate/upload",
		type: "post",
		data: formData,
		processData: false, // 告诉jQuery不要去处理发送的数据
		contentType: false, // 告诉jQuery不要去设置Content-Type请求头
		dataType: 'text',
		success: function(res) {
			var resObj = JSON.parse(res)
			// console.log('上传成功, 返回值resObj', resObj)
			if (resObj.code == 200) {
				// $(`#d${type}`).html(`${htmlArr[type]}_${companyName || fileData.name}_${dayjs().format('DD/MM/YYYY HH:MM')}`)
				$(`#d${type}`).html(resObj.data.fileName)
				oriObj.corporateUploadQOList[type - 1] = {
					affixId: resObj.data.affixId,
					attachmentType: type
				}
			}
		},
		error: function(data) {}
	});
}
