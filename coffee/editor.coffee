
KEY_PGUP = 33
KEY_PGDN = 34
KEY_END = 35
KEY_HOME = 36
KEY_LEFT = 37
KEY_UP = 38
KEY_RIGHT = 39
KEY_DOWN = 40
KEY_BACKSPACE = 8
KEY_DEL = 46

class LineNumberElement
    constructor: (text, options) ->
        @self = new Element('div', options)
        Object.extend(@self, LineNumberElement.prototype)
        @self.init(text)
        return @self
    
    init: (text) ->
        @addClassName 'te-line-number'
        @text = text
        @update @text
        return

class LineElement
    constructor: (text, options) ->
        @self = new Element('div', options)
        Object.extend(@self, LineElement.prototype)
        @self.init(text)
        return @self
    
    init: (text) ->
        @addClassName 'te-line'
        @text = text
        @update @text
        return

class SelectionBar
    constructor: (options) ->
        @self = new Element('div', options)
        Object.extend(@self, SelectionBar.prototype)
        @self.init()
        return @self
    
    init: (text) ->
        @addClassName 'te-selection-bar'
        return
    

class TextEditor

    constructor: (options) ->
        @self = new Element('div', options)
        Object.extend(@self, TextEditor.prototype)
        @self.init()
        return @self
    
    init: () ->
        
        # margin between line number and line text
        @margin = 4
        # padding inbetween lines (both at time and bottom of line)
        @vertical_padding = 1
        
        @text = ''
        @addClassName 'texteditor'
        @setStyle {
            border: '0px red solid'
            cursor: 'text'
            fontFamily: 'monospace'
        }
        
        Event.observe window, 'keydown', (e) => @keydown(e)
        Event.observe window, 'keypress', (e) => @keypress(e)
        Event.observe window, 'keyup', (e) => @keyup(e)
        @observe 'mousedown', (e) => @mousedown(e)
        @observe 'mousemove', (e) => @mousemove(e)
        @observe 'mouseup', (e) => @mouseup(e)
        
        @fontText = new Element 'span', {style: 'padding: 0px; margin: 0px;'}
        @fontText.update 'a'
        
        @lines = new Element 'span', {style: 'border: 1px black solid; background-color #f0f0f0;'}
        
        @cursor = new Element 'span', {id: 'cursor', \
            style: 'padding: 0px; margin: 0px; color: black; border-left: 1px black solid;'}
        @cursor.update '&nbsp;'
        
        @line = 0
        @chr = 0
        
        return

    font_size: () ->
        
        @insert @fontText
        sz = [@fontText.getWidth(), @fontText.getHeight()]
        @fontText.remove()
        
        return sz
    
    refresh_cursor: () ->
    
        if not @cursor_inserted?
            @insert @cursor
            @cursor.absolutize()
            @cursor.show()
            @cursor_inserted = yes
        
        [width, height] = @font_size()
        
        @cursor.setStyle {
            top: (@positionedOffset().top + ((height + (@vertical_padding * 2)) * @line)) + 'px'
            left: (@positionedOffset().left + (@margin * 2) + @line_number_width() + (@chr * width)) + 'px'
            width: width + 'px'
            height: height + 'px'
        }
        
        @cursor.show()
        
        if not @blinker?
            @blinker.stop() if @blinker?
            @blinker = new PeriodicalExecuter((() => @cursor.toggle()), 0.5);
        
        return
    
    mousedown: (e) ->
        
        @select_start = @event_to_loc(e)
        console.log ['mouse down', @select_start]
        
        @update_selection_timer.stop() if @update_selection_timer?
        @update_selection_timer = new PeriodicalExecuter((() => @update_selection()), 0.1);
        
        e.stop()
        
        return
    
    mousemove: (e) ->
        @mouse_moveloc = {srcElement: e.srcElement, offsetX: e.offsetX, offsetY: e.offsetY}
        e.stop()
        return
    
    event_to_loc: (e) ->
        [x, y] = [e.offsetX, e.offsetY]
        
        offset = e.srcElement.viewportOffset().relativeTo(@viewportOffset());
        x += offset.left
        y += offset.top
        
        # adjus for margin and line number
        x -= (@margin * 2) + @line_number_width()
        
        [width, height] = @font_size()
        line = Math.floor(y / (height + (@vertical_padding * 2)))
        chr = Math.floor((x - (width/2)) / width) + 1
        
        line = Math.min(line, @lines.length-1)
        chr = Math.min(chr, @lines[line].length)
        
        return [line, chr]
    
    update_selection: () ->
        
        return if not @mouse_moveloc?
        
        @select_end = @event_to_loc(@mouse_moveloc)
        
        console.log ['updating', @select_end]
        
        [start_line, start_chr] = @select_start
        [end_line, end_chr] = @select_end
        [@line, @chr] = @select_end
        
        @show_selection()
        @refresh_cursor()
        
        return
    
    unselect: () ->
        @select_start = @select_end = null
        @show_selection()
        return
    
    show_selection: () ->
        
        for e in @select('.te-selection-bar')
            e.remove()
        
        if not @select_start? or not @select_end?
            @has_selection = no
            return
        
        [start_line, start_chr] = @select_start
        [end_line, end_chr] = @select_end
        
        # return if there's no selection...
        if start_line == end_line and start_chr == end_chr
            @has_selection = no
            return
        else
            @has_selection = yes
        
        count = Math.abs(start_line-end_line)
        for i in [start_line..end_line]
            bar = new SelectionBar()
            
            @insert bar
            bar.absolutize()
            bar.show()
            
            if end_line < start_line or (start_line == end_line and end_chr < start_chr)
                left = if i == end_line then end_chr else 0
                right = if i == start_line then start_chr else @lines[i].length
            else
                left = if i == start_line then start_chr else 0
                right = if i == end_line then end_chr else @lines[i].length
            
            [width, height] = @font_size()
            bar.setStyle {
                top: (@positionedOffset().top + ((height + (@vertical_padding * 2)) * i)) + 'px'
                left: (@positionedOffset().left + (@margin * 2) + @line_number_width() + (left * width)) + 'px'
                width: ((right - left) * width) + 'px'
                height: height + 'px'
                backgroundColor: '#a0a0a0'
            }
            bar.setOpacity 0.3
        
        return
    
    mouseup: (e) ->
        """ follow whether the user has focus in the textbox """
        
        if @update_selection_timer?
            @update_selection_timer.stop()
            @update_selection_timer = null
        
        @select_end = @event_to_loc(e)
        @show_selection()
        
        #console.log ['mouse up', @select_end]
        
        @has_focus = e.srcElement == @ or e.srcElement.descendantOf @
        return if not @has_focus
        
        if e.srcElement == @
            e.stop()
        
        [@line, @chr] = @event_to_loc(e)
        #console.log ['cliked at', @line, @chr]
        
        @refresh_cursor()
        
        return
    
    cursor_right: (selecting) ->
        
        if selecting and not @has_selection
            @select_start = [@line, @chr]
        
        if @chr+1 > @lines[@line].length
            if @line == @lines.length-1
                @chr = @lines[@line].length
            else
                @line = Math.min(@line+1, @lines.length-1)
                @chr = 0
        else
            @chr += 1
        
        @pin_chr = @chr
        
        if not selecting and @has_selection
            @unselect()
        else if selecting
            @select_end = [@line, @chr]
            @show_selection()
        
        @refresh_cursor()
        return
    
    cursor_left: (selecting) ->
        
        if selecting and not @has_selection
            @select_start = [@line, @chr]
        
        if @chr - 1 < 0
            if @line == 0
                @chr = 0
            else
                @line = Math.max(@line-1, 0)
                @chr = @lines[@line].length
        else
            @chr -= 1
        
        @pin_chr = @chr
        
        if not selecting and @has_selection
            @unselect()
        else if selecting
            @select_end = [@line, @chr]
            @show_selection()
        
        @refresh_cursor()
        return
    
    cursor_down: (selecting) ->
    
        if selecting and not @has_selection
            @select_start = [@line, @chr]
        
        if @line == @lines.length-1
            @chr = @lines[@line].length
        else
            @line += 1
            @chr = Math.min(@pin_chr, @lines[@line].length)
        
        if not selecting and @has_selection
            @unselect()
        else if selecting
            @select_end = [@line, @chr]
            @show_selection()
        
        @refresh_cursor()
        return
    
    cursor_up: (selecting) ->
    
        if selecting and not @has_selection
            @select_start = [@line, @chr]
        
        if @line == 0
            @chr = 0
        else
            @line -= 1
            @chr = Math.min(@pin_chr, @lines[@line].length)
        
        if not selecting and @has_selection
            @unselect()
        else if selecting
            @select_end = [@line, @chr]
            @show_selection()
        
        @refresh_cursor()
        return
    
    cursor_home: (selecting) ->
    
        if selecting and not @has_selection
            @select_start = [@line, @chr]
        
        @chr = @pin_chr = 0
        
        if not selecting and @has_selection
            @unselect()
        else if selecting
            @select_end = [@line, @chr]
            @show_selection()
        
        @refresh_cursor()
        return
    
    cursor_end: (selecting) ->
    
        if selecting and not @has_selection
            @select_start = [@line, @chr]
        
        @chr = @pin_chr = @lines[@line].length
        
        if not selecting and @has_selection
            @unselect()
        else if selecting
            @select_end = [@line, @chr]
            @show_selection()
        
        @refresh_cursor()
        return
    
    keydown: (e) ->
        
        console.log ['keydown', e]
        
        # special delete events
        if e.keyCode == Event.KEY_BACKSPACE
            @delete_backward(e.ctrlKey)
            e.stop()
        else if e.keyCode == Event.KEY_DELETE
            @delete_forward(e.ctrlKey)
            e.stop()
        
        # key events
        else if e.ctrlKey and e.keyCode == Event.KEY_LEFT
            # move cursor before previous word
            @cursor_next_word(e.shiftKey)
            e.stop()
        else if e.ctrlKey and e.keyCode == Event.KEY_RIGHT
            # move cursor after next word
            @cursor_prev_word(e.shiftKey)
            e.stop()
        else if e.keyCode == Event.KEY_RIGHT
            @cursor_right(e.shiftKey)
            e.stop()
        else if e.keyCode == Event.KEY_LEFT
            @cursor_left(e.shiftKey)
            e.stop()
        else if e.keyCode == Event.KEY_UP
            @cursor_up(e.shiftKey)
            e.stop()
        else if e.keyCode == Event.KEY_DOWN
            @cursor_down(e.shiftKey)
            e.stop()
        else if e.keyCode == Event.KEY_HOME
            @cursor_home(e.shiftKey)
            e.stop()
        else if e.keyCode == Event.KEY_END
            @cursor_end(e.shiftKey)
            e.stop()
        
        return
    
    keypress: (e) ->
        console.log ['keypress', e.keyCode]
        
        sel = document.getSelection()
        console.log ['typing', e, sel]
        
        return
    
    keyup: (e) ->
        
        console.log ['keyup', e.keyCode]
        
        return
    
    line_number_width: () ->
    
        [width, height] = @font_size()
        i = @lines.length.toString().length
        
        if width == 0
            width = 8
        return (i+2) * width
    
    update: (text) ->
        """ called after changing @text """
        
        @text = text
        
        # flush everything
        Element.update @, ''
        
        @lines = @text.split('\n')
        
        line_number_width = @line_number_width()
        
        @elements = []
        i = 1
        for line in @lines
            number = new LineNumberElement(i.toString() + '.')
            number.setStyle {'float': 'left', clear: 'left', backgroundColor: '#f0f0f0', \
                width: line_number_width + 'px', paddingLeft: @margin + 'px', \
                marginTop: @vertical_padding + 'px', marginBottom: @vertical_padding + 'px'}
            line = new LineElement(line.replace(/\s/g, '&nbsp;'))
            line.setStyle {'float': 'left', marginLeft: @margin + 'px', \
                marginTop: @vertical_padding + 'px', marginBottom: @vertical_padding + 'px'}
            
            @appendChild number
            @appendChild line
            
            i += 1
        
        return
    
    
    