(function($){
    $.fn.extend({
        websocketVNC: function(options) {
            var vnc = this;

            var defaults = {};

            var options = $.extend(defaults, options);

            vnc.width  = options.width;
            vnc.height = options.height;

            vnc.mousedown = false;

            vnc.queue = [];

            vnc.init = function () {
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

                vnc.canvas.bind('mousedown', function(e) {
                    var pos = vnc.canvas.offset();
                    var x = Math.floor(e.pageX - pos.left);
                    var y = Math.floor(e.pageY - pos.top);
                    vnc.ws.send($.toJSON({"type":"pe","x":x,"y":y,"event":"mousedown"}));
                    vnc.mousedown = true;
                });

                $(document).bind('mouseup', function(e) {
                    vnc.mousedown = false;
                });

                vnc.canvas.bind('mouseup', function(e) {
                    vnc.mousedown = false;
                    var pos = vnc.canvas.offset();
                    var x = Math.floor(e.pageX - pos.left);
                    var y = Math.floor(e.pageY - pos.top);
                    vnc.ws.send($.toJSON({"type":"pe","x":x,"y":y,"event":"mouseup"}));
                });

                vnc.canvas.bind('mousemove', function(e) {
                    var pos = vnc.canvas.offset();
                    var x = Math.floor(e.pageX - pos.left);
                    var y = Math.floor(e.pageY - pos.top);
                    var action = 'mousemove';
                    if (vnc.mousedown) {
                        action += '+mousedown';
                    }
                    vnc.ws.send($.toJSON({"type":"pe","x":x,"y":y,"event":action}));
                });

                vnc.ws.send($.toJSON({"type":"fuq","x":0,"y":0,"width":vnc.width,"height":vnc.height}));

                setTimeout(function () { vnc.update() }, 500);
            };

            vnc.displayMessage = function (msg) {
                $(this).html(msg);
            };

            vnc.update = function () {
                var rectangles = vnc.queue.shift();

                if (!rectangles) {
                    //vnc.ws.send($.toJSON({"type":"fuq","x":0,"y":0,"width":vnc.width,"height":vnc.height,"incremental" : 1}));
                    setTimeout(function () { vnc.update() }, 50);
                    return;
                }

                for (var i = 0; i < rectangles.length; i++) {
                    var x        = rectangles[i].x;
                    var y        = rectangles[i].y;
                    var width    = rectangles[i].width;
                    var height   = rectangles[i].height;
                    var encoding = rectangles[i].encoding;
                    var data     = rectangles[i].data;

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
                    else if (encoding == 'CopyRect') {
                        var img = vnc.context.getImageData(data[0], data[1], width, height);
                        vnc.context.putImageData(img, x, y);
                    }
                }

                vnc.ws.send($.toJSON({"type":"fuq","x":0,"y":0,"width":vnc.width,"height":vnc.height,"incremental" : 1}));
                setTimeout(function () { vnc.update() }, 500);
            };

            return this.each(function() {
                var o = options;

                vnc.displayMessage('Connecting...');

                vnc.ws = new WebSocket(o.url);

                vnc.ws.onerror = function(e) {
                    vnc.displayMessage("Error: " + e);
                };

                vnc.ws.onopen = function() {
                    vnc.init();
                };

                vnc.ws.onmessage = function(e) {
                    var data = $.evalJSON(e.data);

                    if (data.type == 's') {
                        $('#vnc-name').html(data.name);
                        $('#vnc-width').html(data.width);
                        $('#vnc-height').html(data.height);
                    }
                    else if (data.type == 'fu') {
                        vnc.queue.push(data.rectangles);
                    }
                };

                vnc.ws.onclose = function() {
                    vnc.displayMessage('Disconnected. <a href="/">Reconnect</a>');
                };
            });
        }
    });
})(jQuery);
