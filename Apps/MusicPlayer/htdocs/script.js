/* 
 * Gmu Music Player
 *
 * Copyright (c) 2006-2014 Johannes Heimansberg (wejp.k.vu)
 *
 * File: script.js  Created: 120213
 *
 * Description: HTTP/Websocket frontend
 */

var pl = [], fb_dir = [], mb = [];
var dir;
var selected_tab = 'pl';

var con = null;
var plt, fbt, mbt;
var playmode = 0;

window.onload = function() { init(); }

function Connection()
{
	c = this;
	this.socket = null;
	this.disconnected = true;
	this.start = function start(websocketServerLocation)
	{
		if (typeof WebSocket != 'undefined')
			this.socket = new WebSocket(websocketServerLocation);
		else if (typeof MozWebSocket != 'undefined')
			this.socket = new MozWebSocket(websocketServerLocation);

		if (this.socket) {
			this.socket.onclose = function()
			{
				if (!this.disconnected) {
					write_to_screen(": Disconnected from server. Reconnecting...");
					this.disconnected = true;
				}
				//try to reconnect in 2 seconds
				setTimeout('c.start("'+websocketServerLocation+'")', 2000);
			};

			this.socket.onopen = function()
			{
				write_to_screen(": Socket has been opened!");
				this.disconnected = false;
			}

			this.socket.onmessage = function(msg)
			{
				var jmsg = JSON.parse(msg.data);

				switch (jmsg['cmd']) {
					case 'hello':
						if (jmsg['need_password'] == 'yes')
							loginbox_display(1);
						else
							c.login('');
						break;
					case 'login':
						if (jmsg['res'] == 'success') {
							loginbox_display(0);
							c.do_send('{"cmd":"trackinfo"}');
							c.do_send('{"cmd":"playlist_playmode_get_info"}');
							cur_dir = '/';
							dir = undefined;
							c.do_send('{"cmd":"dir_read","dir":"' + cur_dir + '"}');
							mlib_browse('artist');
						}
						break;
					case 'time':
						write_to_time_display(jmsg['time']);
						break;
					case 'playback_state':
						switch(jmsg['state']) {
							case 0: // stop
								document.getElementById("btn-play").className = "button";
								document.getElementById("btn-pause").className = "button";
								document.getElementById("display-play").style.visibility = "hidden";
								document.getElementById("display-pause").style.visibility = "hidden";
								break;
							case 1: // play
								document.getElementById("btn-play").className = "button-pressed";
								document.getElementById("btn-pause").className = "button";
								document.getElementById("display-play").style.visibility = "visible";
								document.getElementById("display-pause").style.visibility = "hidden";
								break;
							case 2: // pause
								document.getElementById("btn-pause").className = "button-pressed";
								document.getElementById("btn-play").className = "button";
								document.getElementById("display-play").style.visibility = "hidden";
								document.getElementById("display-pause").style.visibility = "visible";
								break;
						}
						break;
					case 'trackinfo':
						write_to_screen('Track:' + jmsg['artist'] + ' - ' + jmsg['title']);
						set_trackinfo(jmsg['artist'], jmsg['title'], jmsg['album']);
						break;
					case 'track_change':
						set_trackinfo_playlist_pos("" + jmsg['playlist_pos']);
						break;
					case 'playlist_info':
					case 'playlist_change':
						t = document.getElementById("playlisttable");
						rows = jmsg['length'];
						pl_set_number_of_items(rows);
						for (var i = jmsg['changed_at_position']; i < rows; i++)
							pl[i] = undefined;
						document.getElementById('tpl').innerHTML = 'Playlist ('+rows+')';
						toggle_state = false;
						current_length = t.rows.length;
						for (id = 0; (r = t.rows[id]); id++) {
							r.childNodes[1].innerHTML = '!';
							r.childNodes[2].innerHTML = '?';
						}
						handle_playlist_scroll();
						break;
					case 'playlist_item':
						pl[jmsg['position']] = jmsg['title'];
						if (jmsg['position']-plt.first_visible_line >= 0)
							plt.set_row_data(jmsg['position']-plt.first_visible_line);
						break;
					case 'playback_time':
						min = parseInt((jmsg['time'] / 1000) / 60);
						sec = parseInt((jmsg['time'] / 1000) - min * 60);
						write_to_time_display(min + ':' + (sec < 10 ? '0' : '') + sec);
						break;
					case 'dir_read':
						if (jmsg['res'] == 'ok') {
							cur_dir = jmsg['path'];
							dir = jmsg['data'];
							for (var i in dir) {
								if (i >= 0) {
									if (i == 0) {
										fbt.clear();
										fb_dir = [];
									}
									fb_dir[i] = dir[i];
									write_to_screen('file'+i+'='+dir[i]['name']);
								}
							}
							fbt.set_length(fb_dir.length);
							for (i = 0; i <= fbt.visible_line_count; i++) {
								fbt.set_row_data(i);
							}
							handle_fb_scroll();
						}
						break;
					case 'playmode_info':
						playmode = jmsg['mode'];
						switch (jmsg['mode']) {
							default:
							case 0: // Continue
								document.getElementById("btn-pm-continue").className = "button-pressed";
								document.getElementById("btn-pm-random").className = "button";
								document.getElementById("btn-pm-repeat").className = "button";
								document.getElementById("btn-pm-repeat-track").className = "button";
								break;
							case 1: // Repeat All
								document.getElementById("btn-pm-continue").className = "button";
								document.getElementById("btn-pm-random").className = "button";
								document.getElementById("btn-pm-repeat").className = "button-pressed";
								document.getElementById("btn-pm-repeat-track").className = "button";
								break;
							case 2: // Repeat Track
								document.getElementById("btn-pm-continue").className = "button";
								document.getElementById("btn-pm-random").className = "button";
								document.getElementById("btn-pm-repeat").className = "button";
								document.getElementById("btn-pm-repeat-track").className = "button-pressed";
								break;
							case 3: // Random
								document.getElementById("btn-pm-continue").className = "button";
								document.getElementById("btn-pm-random").className = "button-pressed";
								document.getElementById("btn-pm-repeat").className = "button";
								document.getElementById("btn-pm-repeat-track").className = "button";
								break;
							case 4: // Random+Repeat
								document.getElementById("btn-pm-continue").className = "button";
								document.getElementById("btn-pm-random").className = "button-pressed";
								document.getElementById("btn-pm-repeat").className = "button-pressed";
								document.getElementById("btn-pm-repeat-track").className = "button";
								break;
						}
						break;
					case 'mlib_browse_result':
						if (jmsg['pos'] != undefined) {
							mb[jmsg['pos']] = [];
							mb[jmsg['pos']]['artist'] = jmsg['artist'];
							if (jmsg['pos']-mbt.first_visible_line >= 0)
								mbt.set_row_data(jmsg['pos']-mbt.first_visible_line);
							mbt.set_length(mb.length);
						}
						break;
					case 'mlib_result':
						if (jmsg['pos'] == 0) mb.length = 0;
						handle_mb_scroll();
						mb[jmsg['pos']] = [];
						mb[jmsg['pos']]['artist'] = jmsg['artist'];
						mb[jmsg['pos']]['title'] = jmsg['title'];
						mb[jmsg['pos']]['album'] = jmsg['album'];
						mb[jmsg['pos']]['file'] = jmsg['file'];
						if (jmsg['pos']-mbt.first_visible_line >= 0)
							mbt.set_row_data(jmsg['pos']-mbt.first_visible_line);
						mbt.set_length(mb.length);
						break;
					default:
						if (msg.data != undefined) write_to_screen('msg='+msg.data);
						break;
				}
			}
		} else { /* No WebSocket support */
			write_to_screen('Your web browser does not seem to support WebSockets. :(');
		}
	}

	this.do_send = function do_send(message)
	{
		if (this.socket) {
			try {
				this.socket.send(message);
			} catch (e) {
				this.disconnected = true;
			}
		}
	}

	this.login = function login(password)
	{
		c.do_send('{"cmd":"login","password":"'+password+'"}');
	}
}

function GmuList()
{
	gl = this;
	this.visible_line_count = 0;
	this.first_visible_line = 0;
	this.item_height = 1;
	this.table_elem_id = undefined;
	this.scrollbar_elem_id = undefined;
	this.func_get_data = undefined;
	this.func_item_construct = undefined;
	this.length = 0;
	this.table_elem = undefined;
	this.table_column_size = [5, 90, 5];

	this.init = function(div_elem_id, table_elem_id, scrollbar_elem_id, scrolldummy_elem_id,
	                     func_get_data, func_item_construct, func_need_data)
	{
		this.table_elem_id = table_elem_id;
		this.scrollbar_elem_id = scrollbar_elem_id;
		this.scrolldummy_elem_id = scrolldummy_elem_id;
		this.func_get_data = func_get_data;
		this.func_item_construct = func_item_construct;
		this.func_need_data = func_need_data;
		this.table_elem = document.getElementById(table_elem_id);
		this.table_elem.innerHTML = '';
		this.add_row('?', '?', '?', '#111');
		select_tab(div_elem_id);
		div_elem_id = div_elem_id + 'x';
		var div_elem = document.getElementById(div_elem_id);
		var height = div_elem.clientHeight;
		this.item_height = this.table_elem.clientHeight;
		this.visible_line_count = parseInt(height / this.item_height) + 1;
		for (i = 0; i < this.visible_line_count; i++)
			this.add_row('', '?', '', '#111');
	}

	this.set_table_column_sizes = function(col1_width, col2_width, col3_width)
	{
		this.table_column_size[0] = col1_width;
		this.table_column_size[1] = col2_width;
		this.table_column_size[2] = col3_width;
	}

	this.add_row = function(col1, col2, col3, bg)
	{
		var tabl = document.getElementById(this.table_elem_id);
		var ro   = tabl.insertRow(tabl.rows.length);
		ro.style.backgroundColor = bg;
		cell1 = ro.insertCell(0);
		cell1.innerHTML = col1;
		cell1.style.width = this.table_column_size[0]+"%";
		cell1.style.height = "20px";
		cell2 = ro.insertCell(1);
		cell2.innerHTML = col2;
		cell2.style.width = this.table_column_size[1]+"%";
		cell2.style.height = "20px";
		cell3 = ro.insertCell(2);
		cell3.innerHTML = col3;
		cell3.style.width = this.table_column_size[2]+"%";
		cell3.style.height = "20px";
	}

	/* ros is the number of the visible row -> first visible row=0 */
	this.set_row_data = function(row)
	{
		if ((r = this.table_elem.rows[row])) {
			for (col = 0; col < 3; col++) {
				r.childNodes[col].innerHTML = (this.func_item_construct !== undefined) ?
				                              '<div>'+this.func_item_construct(this.first_visible_line+row, col)+'</div>' : '';
			}
		}
	}

	this.handle_scroll = function()
	{
		this.first_visible_line = parseInt(document.getElementById(this.scrollbar_elem_id).scrollTop / this.item_height);
		for (i = 0; i <= this.visible_line_count; i++) {
			if (this.func_need_data === undefined || !this.func_need_data(this.first_visible_line+i)) {
				this.set_row_data(i);
			} else {
				var j = i;
				do {
					if (this.func_need_data !== undefined && this.func_need_data(this.first_visible_line+j) && 
					    (r = this.table_elem.rows[j])) {
						if (this.first_visible_line+j+1 < this.length) {
							r.childNodes[0].innerHTML = this.first_visible_line+j+1;
							r.childNodes[1].innerHTML = '?';
							r.childNodes[2].innerHTML = '?';
						} else {
							r.childNodes[0].innerHTML = '';
							r.childNodes[1].innerHTML = '';
							r.childNodes[2].innerHTML = '';
						}
					}
					j++;
				} while (j <= this.visible_line_count);
				if (this.first_visible_line+i < this.length && this.func_get_data !== undefined)
					this.func_get_data(this.first_visible_line+i+1);
			}
		}
	}

	this.scroll_n_rows = function(n)
	{
		document.getElementById(this.scrollbar_elem_id).scrollTop += (20 * n);
	}

	this.clear = function()
	{
		this.length = 0;
		document.getElementById(this.scrolldummy_elem_id).style.height = "0px";
	}

	this.set_length = function(items)
	{
		this.length = items;
		document.getElementById(this.scrolldummy_elem_id).style.height = "" + (items*this.item_height) + "px";
	}
}

function write_to_screen(message)
{
	var output = document.getElementById('log');
	var pre = document.createElement("p");
	pre.style.wordWrap = "break-word";
	pre.innerHTML = html_entity_encode(message);
	output.appendChild(pre);
}

function write_to_time_display(message)
{
	var output = document.getElementById('time');
	/*var pre = document.createElement("p");
	pre.style.wordWrap = "break-word";
	pre.innerHTML = message;*/
	output.innerHTML = message;
}

function set_trackinfo(artist, title, album)
{
	document.getElementById('ti-artist').innerHTML = html_entity_encode(artist);
	document.getElementById('ti-title').innerHTML  = html_entity_encode(title);
	document.getElementById('ti-album').innerHTML  = html_entity_encode(album);
}

function set_trackinfo_playlist_pos(pos)
{
	document.getElementById('ti-trackno').innerHTML  = html_entity_encode(pos);
}

function select_tab(tab_id)
{
	elem = document.getElementsByClassName('tab');
	for (i = 0; i < elem.length; i++)
		elem[i].style.display = "none";
	elem = document.getElementsByClassName('tabitem');
	for (i = 0; i < elem.length; i++)
		elem[i].className = elem[i].className.replace("act", "ina");
	t = document.getElementById('t'+tab_id);
	t.className = t.className.replace("ina", "act");
	document.getElementById(tab_id).style.display = "block";
	selected_tab = tab_id;
}

function play(id)
{
	con.do_send('{"cmd":"play","item":'+id+'}');
}

function remove(id)
{
	con.do_send('{"cmd":"playlist_item_delete","item":'+id+'}');
}

function pl_set_number_of_items(items)
{
	pl.length = rows;
	plt.set_length(items);
}

function add_event_handler(elem_id, event, event_handler)
{
	elem = document.getElementById(elem_id);
	if (elem.attachEvent) // if IE (and Opera depending on user setting)
		elem.attachEvent("on"+event, event_handler);
	else if (elem.addEventListener) // W3C browsers
		elem.addEventListener(event, event_handler, false);
}

function handle_playlist_scroll()
{
	plt.handle_scroll();
}

function handle_fb_scroll()
{
	fbt.handle_scroll();
}

function handle_mb_scroll()
{
	mbt.handle_scroll();
}

function handle_mouse_scroll_event(e)
{
	var evt = window.event || e; // equalize event object
	// delta returns +120 when wheel is scrolled up, -120 when scrolled down
	var delta = evt.detail ? evt.detail * (-120) : evt.wheelDelta;
	direction = (delta <= -120) ? 1 : -1;
	switch (selected_tab) {
		case 'pl':
			plt.scroll_n_rows(direction);
			break;
		case 'fb':
			fbt.scroll_n_rows(direction);
			break;
		case 'mb':
			mbt.scroll_n_rows(direction);
			break;
	}
}

function handle_btn_next(e)
{
	con.do_send('{"cmd":"next"}');
}

function handle_btn_prev(e)
{
	con.do_send('{"cmd":"prev"}');
}

function handle_btn_play(e)
{
	con.do_send('{"cmd":"play"}');
}

function handle_btn_pause(e)
{
	con.do_send('{"cmd":"pause"}');
}

function handle_btn_stop(e)
{
	con.do_send('{"cmd":"stop"}');
}

function handle_btn_clear(e)
{
	con.do_send('{"cmd":"playlist_clear"}');
}

function handle_btn_playmode(e)
{
	if (!e) var e = window.event;
	if (e.target)
		telem = e.target;
	else if (e.srcElement)
		telem = e.srcElement;
	if (telem.nodeType == 3) // Defeat Safari bug
		telem = telem.parentNode;
	if (telem.className == 'icon') telem = telem.parentNode;
	bcont = document.getElementById('btn-pm-continue');
	brand = document.getElementById('btn-pm-random');
	brepa = document.getElementById('btn-pm-repeat');
	brept = document.getElementById('btn-pm-repeat-track');
	switch (telem) {
		case bcont:
			mode = 0;
			break;
		case brand:
			if (playmode == 1)      // repeat
				mode = 4;
			else if (playmode == 3) // random
				mode = 0;
			else if (playmode == 4) // random+repeat
				mode = 1;
			else
				mode = 3;
			break;
		case brepa:
			if (playmode == 3)
				mode = 4;
			else if (playmode == 1)
				mode = 0;
			else if (playmode == 4)
				mode = 3;
			else
				mode = 1;
			break;
		case brept:
			if (playmode == 2)
				mode = 0;
			else
				mode = 2;
			break;
	}
	con.do_send('{"cmd":"playlist_playmode_set","mode":'+mode+'}');
}

function handle_tab_select_fb(e)
{
	var evt = window.event || e;
	select_tab('fb');
}

function handle_tab_select_mb(e)
{
	var evt = window.event || e;
	select_tab('mb');
}

function handle_tab_select_pl(e)
{
	var evt = window.event || e;
	select_tab('pl');
}

function handle_tab_select_log(e)
{
	var evt = window.event || e;
	select_tab('lo');
}

function handle_keypress(e)
{
	// Page up: 33, down: 34, Crsr down: 40, up: 38
	switch (selected_tab) {
		case 'pl':
			if (e.keyCode == 40)      // Cursor down
				plt.scroll_n_rows(1);
			else if (e.keyCode == 38) // Cursor up
				plt.scroll_n_rows(-1);
			break;
		case 'fb':
			if (e.keyCode == 40)      // Cursor down
				fbt.scroll_n_rows(1);
			else if (e.keyCode == 38) // Cursor up
				fbt.scroll_n_rows(-1);
			break;
		case 'mb':
			if (e.keyCode == 40)      // Cursor down
				mbt.scroll_n_rows(1);
			else if (e.keyCode == 38) // Cursor up
				mbt.scroll_n_rows(-1);
			break;
		default:
			break;
	}
}

function loginbox_display(show)
{
	if (show) d = 'block'; else d = 'none';
	document.getElementById('loginbox').style.display = d;
}

function handle_login(e)
{
	e.preventDefault();
	passwd = document.getElementById('password').value;
	con.login(passwd);
	return false;
}

function pl_item_row_construct(item, col)
{
	var res;
	switch (col) {
		default:
		case 0:
			res = item+1;
			break;
		case 1:
			res = "<a href=\"javascript:play("+item+");\">"+
			      html_entity_encode(pl[item])+"</a>";
			break;
		case 2:
			res = "<a title=\"Remove item\" class=\"icon\" href=\"javascript:remove("+item+");\">&#10007;</a>";
			break;
	}
	return res;
}

function pl_need_data(row)
{
	return pl[row] === undefined;
}

function fb_item_row_construct(item, col)
{
	var res;
	switch (col) {
		default:
		case 0:
			if (fb_dir[item] !== undefined)
				res = fb_dir[item]['is_dir'] ? '[DIR]' : parseInt(fb_dir[item]['size'] / 1024);
			else
				res = '';
			break;
		case 1:
			if (fb_dir[item] !== undefined) {
				var path = cur_dir+fb_dir[item]['name'];
				var path_mask = path.replace(/'/g, "\\'");
				res = fb_dir[item]['is_dir'] ?
				      "<a href=\"javascript:add_dir('"+path_mask+"');\"><strong title='Add this directory to playlist'>+</strong></a> <a href=\"javascript:open_dir('"+html_entity_encode(path_mask)+"');\">" + html_entity_encode(fb_dir[item]['name']) + "</a>" :
				      "<a href=\"javascript:add_file('"+path_mask+"');\"><strong title='Add this file to playlist'>+</strong> " + html_entity_encode(fb_dir[item]['name']) + "</a>";
				}
			else
				res = '';
			break;
		case 2:
			res = '';
			break;
	}
	return res;
}

function str_escape(str)
{
	str = str.replace(/'/g, "\\'");
	return str.replace(/"/g, "\\\"");
}

function mb_item_row_construct(item, col)
{
	var res;
	if (mb[item] != undefined) {
		switch (col) {
			default:
			case 0:
				res = '';
				if (mb[item]['artist'] !== undefined) {
					var str = str_escape(mb[item]['artist']);
					res = "<a href=\"javascript:mlib_find('"+html_entity_encode(str)+"');\">" + html_entity_encode(mb[item]['artist']) + "</a>";
				}
				break;
			case 1:
				res = '';
				if (mb[item]['title'] !== undefined && mb[item]['file'] != undefined) {
					var path_mask = str_escape(mb[item]['file']);
					res = "<a href=\"javascript:add_file('"+html_entity_encode(path_mask)+"');\">" + html_entity_encode(mb[item]['title']) + "</a>";
				}
				break;
			case 2:
				res = '';
				if (mb[item]['album'] !== undefined) {
					var str = str_escape(mb[item]['album']);
					res = "<a href=\"javascript:mlib_find('"+html_entity_encode(str)+"');\">" + html_entity_encode(mb[item]['album']) + "</a>";
				}
				break;
		}
	} else {
		res = '?';
	}
	return res;
}

function open_dir(path)
{
	c.do_send('{"cmd":"dir_read","dir":"' + path + '"}');
}

function add_file(path)
{
	c.do_send('{"cmd":"playlist_add","path":"' + path + '","type":"file"}');
}

function add_dir(path)
{
	c.do_send('{"cmd":"playlist_add","path":"' + str_escape(path) + '","type":"dir"}');
}

function mlib_find(str)
{
	c.do_send('{"cmd":"medialib_search","str":"' + str_escape(str) + '","type":"0"}');
}

function mlib_browse(str)
{
	c.do_send('{"cmd":"medialib_browse","column":"' + str_escape(str) + '"}');
}

function html_entity_encode(str)
{
	var str = str.replace(/\&/g,'&amp;');
	str = str.replace(/</g,'&lt;');
	str = str.replace(/>/g,'&gt;');
	str = str.replace(/\'/g,'&#039;');
	str = str.replace(/\"/g,'&quot;');
	return str;
}

function init()
{
	con = new Connection();

	fbt = new GmuList();
	fbt.init('fb', 'filebrowsertable', 'fbscrollbar', 'fbscrolldummy',
	         undefined,
	         fb_item_row_construct
	);

	mbt = new GmuList();
	mbt.set_table_column_sizes(34, 33, 33);
	mbt.init('mb', 'medialibbrowsertable', 'mbscrollbar', 'mbscrolldummy',
	         undefined,
	         mb_item_row_construct
	);

	plt = new GmuList();
	plt.init('pl', 'playlisttable', 'plscrollbar', 'plscrolldummy',
	         function(item)
	         {
				 con.do_send('{"cmd":"playlist_get_item","item":'+(item-1)+'}');
	         },
	         pl_item_row_construct,
	         pl_need_data
	);

	// FF doesn't recognize mousewheel as of FF3.x
	var mwevt = (/Firefox/i.test(navigator.userAgent))? "DOMMouseScroll" : "mousewheel";

	document.onkeydown = handle_keypress;
	add_event_handler('pl',          mwevt,    handle_mouse_scroll_event);
	add_event_handler('fb',          mwevt,    handle_mouse_scroll_event);
	add_event_handler('mb',          mwevt,    handle_mouse_scroll_event);
	add_event_handler('btn-next',    'click',  handle_btn_next);
	add_event_handler('btn-prev',    'click',  handle_btn_prev);
	add_event_handler('btn-play',    'click',  handle_btn_play);
	add_event_handler('btn-pause',   'click',  handle_btn_pause);
	add_event_handler('btn-stop',    'click',  handle_btn_stop);
	add_event_handler('plscrollbar', 'scroll', handle_playlist_scroll);
	add_event_handler('fbscrollbar', 'scroll', handle_fb_scroll);
	add_event_handler('mbscrollbar', 'scroll', handle_mb_scroll);
	add_event_handler('tfb',         'click',  handle_tab_select_fb);
	add_event_handler('tmb',         'click',  handle_tab_select_mb);
	add_event_handler('tpl',         'click',  handle_tab_select_pl);
	add_event_handler('tlo',         'click',  handle_tab_select_log);
	add_event_handler('btn-login',   'click',  handle_login);
	add_event_handler('btn-pl-clear','click',  handle_btn_clear);
	add_event_handler('btn-pm-continue','click',      handle_btn_playmode);
	add_event_handler('btn-pm-random','click',        handle_btn_playmode);
	add_event_handler('btn-pm-repeat','click',        handle_btn_playmode);
	add_event_handler('btn-pm-repeat-track','click',  handle_btn_playmode);
	con.start("ws://" + document.location.host + "/gmu");
	window.onresize = function(event) {
		plt.init('pl', 'playlisttable', 'plscrollbar', 'plscrolldummy',
			 function(item)
			 {
				con.do_send('{"cmd":"playlist_get_item","item":'+(item-1)+'}');
			 },
			 pl_item_row_construct,
			 pl_need_data
		);
		fbt.init('fb', 'filebrowsertable', 'fbscrollbar', 'fbscrolldummy',
			undefined,
			fb_item_row_construct
		);
		mbt.init('mb', 'medialibbrowsertable', 'mbscrollbar', 'mbscrolldummy',
	         undefined,
	         mb_item_row_construct
		);
		handle_playlist_scroll();
		handle_fb_scroll();
		handle_mb_scroll();
	}
}
