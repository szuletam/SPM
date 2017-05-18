window.ysy = window.ysy || {};
ysy.view = ysy.view || {};
ysy.view.getGanttBackground = function () {
  var colors = {
    weekend: "#eeeeee",
    selected: "#ffec6e",
    selected_weekend: "#F4E88A",
    line: "#ebebeb",
    line_selected: "#ffec6e",
    line_month: "#aaaaff",
    assignee: "#bbbbbb"
  };
  return {
    container: gantt.$task_bg,
    renderer: true,
    filter: gantt._create_filter(['_filter_task', '_is_chart_visible', '_is_std_background']),
    _render_bg_canvas: function (canvas, items, limits) {
      var rowHeight = gantt.config.row_height;
      var cfg = gantt._tasks;
      var widths = cfg.width;
      var fullHeight = rowHeight * (limits.toY - limits.fromY);
      var fullWidth = 0;
      var needClear = true;
      var width;
      var partWidth;
      var context = canvas.getContext('2d');
      for (var i = limits.fromX; i < limits.toX; i++) {
        fullWidth += widths[i];
      }
      if (canvas.height !== fullHeight) {
        canvas.style.height = fullHeight + "px";
        canvas.height = fullHeight;
        needClear = false;
      }
      if (canvas.width !== fullWidth) {
        canvas.style.width = fullWidth + "px";
        canvas.width = fullWidth;
        needClear = false;
      }
      //  -- CLEARING --
      if (needClear) {
        context.clearRect(0, 0, fullWidth, fullHeight);
      }
      //  -- WEEKENDS BACKGROUND --
      if (gantt.config.scale_unit === "day") {
        partWidth = 0;
        context.fillStyle = colors.weekend;
        for (i = limits.fromX; i < limits.toX; i++) {
          width = widths[i];
          if (cfg.weekends[i]) {
            context.fillRect(partWidth, 0, width, fullHeight);
          }
          partWidth += width;
        }
      }
      //  -- HORIZONTAL LINES --
      context.strokeStyle = colors.line;
      context.beginPath();
      for (i = 1; i <= limits.toY - limits.fromY; i++) {
        context.moveTo(0, i * rowHeight - 0.5);
        context.lineTo(fullWidth, i * rowHeight - 0.5);
      }
      //  -- VERTICAL LINES --
      partWidth = -0.5;
      for (i = limits.fromX; i < limits.toX; i++) {
        width = widths[i];
        if (width <= 0) continue; //do not render skipped columns
        partWidth += width;
        context.moveTo(partWidth, 0);
        context.lineTo(partWidth, fullHeight);
      }
      context.stroke();
      //  -- SELECTED --
      for (i = limits.fromY; i < limits.toY; i++) {
        if (gantt.getState().selected_task == items[i].id) {
          break;
        }
      }
      //  -- SELECTED ROW --
      if (i < limits.toY) {
        context.fillStyle = colors.selected;
        context.fillRect(0, (i - limits.fromY) * rowHeight, fullWidth, rowHeight);
      }
      //  -- SELECTED WEEKENDS --
      if (gantt.config.scale_unit === "day") {
        partWidth = 0;
        context.fillStyle = colors.selected_weekend;
        for (var j = limits.fromX; j < limits.toX; j++) {
          width = widths[j];
          if (cfg.weekends[j]) {
            context.fillRect(partWidth, i * rowHeight, width, rowHeight);
          }
          partWidth += width;
        }
      }
      if (ysy.settings.resource.open) {
        //  -- ASSIGNEE BACKGROUND --
        context.globalAlpha = 0.5;
        context.fillStyle = colors.assignee;
        for (i = limits.fromY; i < limits.toY; i++) {
          if (items[i].type === "assignee") {
            context.fillRect(0, (i - limits.fromY) * rowHeight, fullWidth, rowHeight);
          }
        }
        context.globalAlpha = 1;
      }
      //  -- BLUE LINE --
      if (gantt.config.scale_unit === "day") {
        partWidth = 0.5;
        context.strokeStyle = colors.line_month;
        context.beginPath();
        for (i = limits.fromX; i < limits.toX; i++) {
          width = cfg.width[i];
          var first = moment(cfg.trace_x[i]).date() === 1;
          if (first) {
            context.moveTo(partWidth, 0);
            context.lineTo(partWidth, fullHeight);
          }
          partWidth += width;
        }
        context.stroke();
      }
    },
    render_bg_line: function (canvas, index, item) {

    },
    render_item: function (item, container) {
      ysy.log.debug("render_item BG", "canvas_bg");
    },
    render_items: function (items, container) {
      ysy.log.debug("render_items FULL BG", "canvas_bg");
      container = container || this.node;
      if (this.rendered === undefined)this.rendered = {};
      var cfg = gantt._tasks;
      var rowHeight = gantt.config.row_height;
      var colWidth = cfg.col_width;
      var countX = cfg.count;
      var countY = items.length;
      var fullHeight = rowHeight * countY;
      //var fullWidth = cfg.full_width;
      var partCountY = Math.ceil(8170 / rowHeight),
          partCountX = Math.ceil(8170 / colWidth);

      for (var y = 0; y * partCountY < countY; y++) {
        if (this.rendered[y] === undefined) this.rendered[y] = {};
        for (var x = 0; x * partCountX < countX; x++) {
          var canvas = this.rendered[y][x];
          if (canvas === undefined) {
            canvas = document.createElement("canvas");
            container.appendChild(canvas);
            canvas.style.float = "left";
            this.rendered[y][x] = canvas;
          }
          this._render_bg_canvas(canvas, items, {
            fromX: x * partCountX,
            toX: Math.min((x + 1) * partCountX, countX),
            fromY: y * partCountY,
            toY: Math.min((y + 1) * partCountY, countY)
          });
        }
      }
      container.style.height = fullHeight + "px";
    }
  };
};