(function($){
    $.fn.extend({
        websocketVNC: function(options) {
            var vnc = this;

            var defaults = {};

            var options = $.extend(defaults, options);

            vnc.width = options.width;
            vnc.height = options.height;

            this.displayMessage = function (msg) {
                $(this).html(msg);
            };

            return this.each(function() {
                var o = options;

                vnc.displayMessage('Connecting...');

                var ws = new WebSocket(o.url);

                ws.onerror = function(e) {
                    vnc.displayMessage("Error: " + e);
                };

                ws.onopen = function() {
                    vnc.displayMessage('Connected. Loading...');

                    vnc.html('');

                    vnc.append('<div><span id="vnc-name"></span>:<span id="vnc-width"></span>x<span id="vnc-height"></span></div>');
                    vnc.append('<canvas width="' + vnc.width + '" height="' + vnc.height + '"></canvas>');
                    vnc.canvas = $('canvas');
                    vnc.context = vnc.canvas[0].getContext('2d');
                    if (!vnc.context) {
                        alert('Error: failed to getContext!');
                        return;
                    }
                    vnc.context.fillRect(0, 0, vnc.width, vnc.height);
                };

                ws.onmessage = function(e) {
                    var data = $.evalJSON(e.data);

                    if (data.type == 's') {
                        $('#vnc-name').html(data.name);
                        $('#vnc-width').html(data.width);
                        $('#vnc-height').html(data.height);
                    }
                    else if (data.type == 'fu') {
                        var rectangles = data.rectangles;
                        for (var i = 0; i < rectangles.length; i++) {
                            var x = rectangles[i].x;
                            var y = rectangles[i].y;
                            var width = rectangles[i].width;
                            var height = rectangles[i].height;
                            var encoding = rectangles[i].encoding;
                            var data = rectangles[i].data;

                            if (encoding == 'Raw') {
                                //var img = vnc.context.createImageData(width, height);
                                var img = vnc.context.getImageData(0, 0, width, height);
                                var pix = img.data;

                                for (var j = 0; j < data.length; j++) {
                                    var color = data[j];

                                    // Red
                                    pix[j * 4] = color[0];

                                    // Green
                                    pix[j * 4 + 1] = color[1];

                                    // Blue
                                    pix[j * 4 + 2] = color[2];
                                }

                                vnc.context.putImageData(img, x, y);
                            }
                        }
                    }
                };

                ws.onclose = function() {
                    vnc.displayMessage('Disconnected. <a href="/">Reconnect</a>');
                };
            });
        }
    });
})(jQuery);
