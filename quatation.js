var QUOT_API_URL = "//api.jijinhao.com";

var MyQuotStock = {};
/**
 * 取数据后生成的图
 * @param {Object} codes 行情代码
 * @param {Object} currentPage 当前页
 * @param {Object} pageSize 页长
 * @param {Number} style 样式 行情类型 1一分钟,2五分钟,3一小时,4一天
 * @param {String} renderTo 显示的div
 * @param {Number} width div宽度
 * @param {Number} height div高度
 * @param {String} colors 显示的颜色
 * @param {String} creditsText credits标题
 * @param {String} creditsHref credits连接
 * @param {Number} xTickPixelInterval x轴时间刻度,单位：px
 * @param {Number} xRange x轴时间长度
 * @param {boolean} refresh 是否强制刷新
 */
MyQuotStock.quotCodesStock = function (codes, currentPage, pageSize, style,
                                       renderTo, width, height, colors, creditsText, creditsHref,
                                       xTickPixelInterval, xRange, refresh) {
    var param = "";
    if (codes != null && codes != "") {
        param = "codes=" + encodeURIComponent(codes);
    }
    if (style == null || style == "") {
        style = 0;
    }
    param += "&style=" + style;
    if (currentPage == null || currentPage == "") {
        currentPage = 1;
    }
    if (pageSize == null || pageSize == "" || pageSize == 0) {
        pageSize = 10;
    }
    if ($('#' + renderTo).attr("show_flag") == "1" && !refresh) {
        return false;
    }
    var url = QUOT_API_URL + "/history/quotejs.htm?" + param
        + "&currentPage=" + currentPage + "&pageSize=" + pageSize;
    // 兼容版本
    loadScript('https://res.quheqihuo.com??/www/js/common/echarts5.3.2.min.js', function() {
        $.getScript(url, function () {
            var json = quot_str;
            var data63 = [];
            var data59 = [];
            var datass = [];
            var datas = [];
            var name = "";
            if (json != null && json != "") {
                for (var i = 0; i < json.length; i++) {
                    var data = $(json[i]).attr('data');
                    for (var d = data.length; d >= 0; d--) {
                        var quote = $(data[d]).attr('quote');
                        if (typeof quote == "undefined")
                            continue;
                        var code = $(quote).attr('q124');
                        if (typeof code == "undefined")
                            continue;
                        if (code != codes) {
                            continue;
                        }
                        var q59 = $(quote).attr('q59');
                        var q63 = $(quote).attr('q63');
                        var q4 = $(quote).attr('q4');

                        q4 = parseFloat(q4);
                        var yyyy = q59.substring(0, 4);
                        var mth = q59.substring(5, 7);
                        var dd = q59.substring(8, 10);
                        var hh = q59.substring(11, 13);
                        var mm = q59.substring(14, 16);
                        var ss = q59.substring(17, 19);
                        if (mth >= 11) {
                            mth = mth - 1;
                        } else if (mth > 1) {
                            mth = mth - 1;
                            mth = "0" + mth;
                        } else {
                            mth = 12;
                            yyyy = yyyy - 1;
                        }
                        if (q59) {
                            data59.push(q59);
                        }
                        data63.push(parseFloat(q63));
                        var dateOne = [];
                        var time = (new Date(yyyy, mth, dd, hh, mm, ss))
                            .getTime();
                        q63 = parseFloat(q63);
                        datas.push([time, q63]);
                        name = $(quote).attr('q67');
                    }
                }

            }

            $('#'+renderTo).css({ width: '100%', height: '100%' })

            var option = {
                animation: false,
                
                grid: {
                    containerLabel: true,
                    top: 5,
                    bottom: '5%'
                },
                tooltip : {
                    trigger: 'axis'
                },
                xAxis : {
                    type: 'category',
                    data: datas.map(function(item){return new Date(item[0]).pattern("MM-dd hh:mm")}),

                    
                    axisLabel: {
                        show: false
                    },
                },
                yAxis : {
                    gridLineColor : '#F0F0F0',
                    type: 'value',
                    axisLabel: {
                        show: false
                    },
                    scale: true
                },
                legend: {
                    show: false
                },
                colors : [colors],
                series : [{
                    name : name,
                    data : datas.map(function(item){return item[1]}),
                    type : 'line',
                    symbolSize: 0
                }]
            }
            var params = {aria: {
                enabled: false // 👈 关键！
            }}
            if (width || height) {
                params.width = width
                params.height = height
            }
            var el = document.getElementById(renderTo)
            if (!window._myChart) window._myChart = {}
            _myChart[renderTo] = echarts.init(el, null, params)
            _myChart[renderTo].setOption(option)
            _myChart[renderTo].resize();
            $('#' + renderTo).attr({'show_flag': "1"});
        });
    })

};

function loadScript(url, callback) {
    // 判断是否已加载资源
    var scriptEles = document.getElementsByTagName("script");
    var urlPath = url.split('.com') && url.split('.com')[1]
    for (var i = 0; i < scriptEles.length; i++) {
        if (scriptEles[i].src.indexOf(urlPath) > -1) {
            if (callback) callback()
            return false
        }
    }
    var script = document.createElement("script");
    script.type = "text/javascript";
    if (script.readyState) { //IE
        script.onreadystatechange = function() {
            if (script.readyState == "loaded" || script.readyState == "complete") {
                script.onreadystatechange = null;
                if (callback) callback()
            }
        };
    } else { //Others
        script.onload = function() {
            if (callback) callback()
        };
    }
    script.src = url;
    document.getElementsByTagName("head")[0].appendChild(script);
}

Date.prototype.Format = function (fmt) {
        var o = {
        "M+": this.getMonth() + 1, //月份 
        "d+": this.getDate(), //日 
        "h+": this.getHours(), //小时 
        "m+": this.getMinutes(), //分 
        "s+": this.getSeconds(), //秒 
        "q+": Math.floor((this.getMonth() + 3) / 3), //季度 
        "S": this.getMilliseconds() //毫秒 
        };
        if (/(y+)/.test(fmt)) fmt = fmt.replace(RegExp.$1, (this.getFullYear() + "").substr(4 - RegExp.$1.length));
        for (var k in o)
        if (new RegExp("(" + k + ")").test(fmt)) 
        fmt = fmt.replace(RegExp.$1, (RegExp.$1.length == 1) ? (o[k]) : (("00" + o[k]).substr(("" + o[k]).length)));
        return fmt;
}

var QuotList = {};
var flag = true;
/**
 * 查询行情
 * @param {Object} codes        行情代码
 * @param {Object} categoryId   行情分类ID
 * @param {Object} tableArray   显示table
 * @param {Object} showId      显示位置
 * @param {Object} currentPage  当前页码
 * @param {Object} pageSize  页长
 * @param {Number} number       小数点后保留位数
 * @param {Number} style        样式
 * @param {Boolean} isFirst     是否第一次取数据
 * @param {String} suffix       class后缀
 * @param {String} parentId  展示行情的table id
 * @param {String} order        排序字段，名称：showName代码：code优先级：priority 
 * @param {String} direction    排序方向：顺序：asc倒序：desc
 * @param {Object} plateId    行情板快ID
 * @param {Boolean} isArrows    是否显示箭头↑↓
 */
QuotList.SearchQuot = function(codes,categoryId,tableArray,showId,currentPage,pageSize,number,style,isFirst,suffix,parentId,order,direction,plateId,isArrows){
    if(suffix == null){
        suffix = "";
    }
    if(parentId == null){
        parentId = ".";
    } else {
        if (parentId.indexOf("table") >= 0) {
            parentId = "#" + parentId + " td.";
        } else {
           parentId = "#" + parentId + " span.";
        }
        
    }
    if(isFirst == null){
        isFirst = "false";
    }
    if(currentPage == null || currentPage == ""){
        currentPage = 1;
    }
    if(pageSize == null || pageSize == "" || pageSize == 0){
        pageSize = 10;
    }
    
    var param = "";
    if(codes != null && codes != ""){
        param = "codes="+encodeURIComponent(codes);
    }
    if(categoryId != null && categoryId != ""){
        param = "categoryId="+categoryId;
    }
    if(plateId != null && plateId != ""){
        param = "plateId="+plateId;
    }
    if(order != null && order != ""){
        param += "&order="+order;
    }
    if(direction != null && direction != ""){
        param += "&direction="+direction;
    }
    
    var url = QUOT_API_URL+"/realtime/quotejs.htm?" + param + "&currentPage=" + currentPage + "&pageSize=" + pageSize;
    $.getScript(url, function(){
        var json = quot_str;
        if(json != null && json != ""){
            for(var i = 0;i<json.length;i++){
                var data = $(json[i]).attr('data');
                for(var d = 0;d<data.length;d++){
                    var quote = $(data[d]).attr('quote');
                    if(typeof quote == "undefined")
                        continue;
                    var code = $(quote).attr('q124');        //取当前行情的行情代码
                    if(typeof code == "undefined")
                        continue;
                    code = QuotList.EscapeChar(code);
                    for(var a = 0; a<tableArray.length; a++){   //需要用行情的常量与行情代码组成唯一的标识 (如：q63  行情代码为USDCNY  即唯一标识为q63USDCNY)
                        var uniqueId = parentId + code + tableArray[a] + suffix;
                        var value = $(quote).attr(tableArray[a]);
                        if(tableArray[a] == 'q124' || tableArray[a] == 'q68' || tableArray[a] == 'q67' || tableArray[a] == 'q59'){
                            $(uniqueId).html(value);
                            continue;
                        }

                        var isPercent = false;
                        if(tableArray[a] == 'q80'){
                            isPercent = true;
                        }
                        var upDown = quote.q70;   //取出涨跌价
                        
                        var v = "--";
                        if(style != null && style !=""){
                            if(value == null || value == "" || value == 0){
                                v = "--";
                            }else if(style.indexOf(tableArray[a]) >= 0 && upDown > 0 ){
                                if(isArrows && tableArray[a] == 'q70'){
                                    if(number != 0){
                                        v = "<font color='#F93A4A'>"+format(value,number)+"↑</font>";
                                    }else{  
                                        v = "<font color='#F93A4A'>"+parseInt(value)+"↑</font>";
                                    }
                                }else{
                                    if(number != 0){
                                        v = "<font color='#F93A4A'>"+format(value,number) + (isPercent ? '%' : '')+"</font>";
                                    }else{
                                        v = "<font color='#F93A4A'>"+parseInt(value) + (isPercent ? '%' : '')+"</font>";
                                    }
                                }
                            }else if(style.indexOf(tableArray[a]) >= 0 && upDown < 0){
                                if(isArrows && tableArray[a] == 'q70'){
                                    if(number != 0){
                                        v = "<font color='#00B578'>"+format(value,number)+"↓</font>";
                                    }else{ 
                                        v = "<font color='#00B578'>"+parseInt(value)+"↓</font>";
                                    }
                                }else{
                                    if(number != 0){
                                        v = "<font color='#00B578'>"+format(value,number) + (isPercent ? '%' : '')+"</font>";
                                    }else{
                                        v = "<font color='#00B578'>"+parseInt(value) + (isPercent ? '%' : '')+"</font>";
                                    }
                                }
                            }else{
                                if(number != 0){
                                    v = format(value,number);
                                    v = tableArray[a] == 'q80' ? parseFloat(value) + '%' : parseFloat(value)
                                    if(v == null || v == "" || v == 0){
                                        v = "--";
                                    }
                                }else{
                                    v = parseInt(value);
                                }
                            }
                        }else{
                            if(value == null || value == "" || value == 0){
                                v = "--";
                            } else {
                                if(number != 0){
                                    v = format(value,number);
                                    v = parseFloat(v);
                                    if(v == null || v =="" || v == 0){
                                        v = "--";
                                    }
                                }else{
                                    v = parseInt(value);
                                }
                            }
                            
                        }
                        if(v == null || v == "" || v == 0){
                            v = "--";
                        }
                        $(uniqueId).html(v);
                    }
                }
            }
        }
    });
}
QuotList.EscapeChar = function(uniCode){
    if(uniCode.indexOf('.')){
    uniCode = uniCode.replace(/\./g,'\\.');
    }
    if(uniCode.indexOf('+')){
        uniCode = uniCode.replace(/\+/g,'\\+');
    }
    if(uniCode.indexOf(')')){
        uniCode = uniCode.replace(/\)/g,'\\)');
    }
    if(uniCode.indexOf('(')){
        uniCode = uniCode.replace(/\(/g,'\\(');
    }
    
    return uniCode;
}


Date.prototype.pattern=function(fmt) {
    var o = {
        "M+" : this.getMonth()+1, //月份
        "d+" : this.getDate(), //日 
        "h+" : this.getHours()%12 == 0 ? 12 : this.getHours()%12, //小时
        "H+" : this.getHours(), //小时     
        "m+" : this.getMinutes(), //分
        "s+" : this.getSeconds(), //秒     
        "q+" : Math.floor((this.getMonth()+3)/3), //季度      
        "S" : this.getMilliseconds() //毫秒     
    };
    var week = {
        "0" : "日",
        "1" : "一",
        "2" : "二",  
        "3" : "三",  
        "4" : "四", 
        "5" : "五", 
        "6" : "六"  
    };       
    if(/(y+)/.test(fmt)){
        fmt=fmt.replace(RegExp.$1, (this.getFullYear()+"").substr(4 - RegExp.$1.length));
    }      
    if(/(E+)/.test(fmt)){
        fmt=fmt.replace(RegExp.$1, ((RegExp.$1.length>1) ? (RegExp.$1.length>2 ? "星期" : "周") : "")+week[this.getDay()+""]);
    }      
    for(var k in o){
        if(new RegExp("("+ k +")").test(fmt)){
            fmt = fmt.replace(RegExp.$1, (RegExp.$1.length==1) ? (o[k]) : (("00"+ o[k]).substr((""+ o[k]).length)));
        }        
    }      
    return fmt;
}

function format(s, n) {
    n = n > 0 && n <= 20 ? n : 2;
    s = parseFloat((s + "").replace(/[^\d\.-]/g, "")).toFixed(n) + "";
    var l = s.split(".")[0].split("").reverse(), r = s.split(".")[1];
    t = "";
    for (i = 0; i < l.length; i++) {
        t += l[i];   // + ((i + 1) % 3 == 0 && (i + 1) != l.length ? "" : "");    //对数据进行分解，每三位 以逗号分隔
    }
    return t.split("").reverse().join("") + "." + r;
}





