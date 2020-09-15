import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lunarCalendar/calendar_provider.dart';
import 'package:lunarCalendar/constants/constants.dart';
import 'package:lunarCalendar/controller.dart';
import 'package:lunarCalendar/model/date_model.dart';
import 'package:lunarCalendar/utils/LogUtil.dart';
import 'package:lunarCalendar/utils/date_util.dart';
import 'package:lunarCalendar/widget/month_view_pager.dart';
import 'package:lunarCalendar/widget/week_view_pager.dart';
import 'package:provider/provider.dart';

/**
 * 暂时默认是周一开始的
 */

//由于旧的代码关系。。所以现在需要抽出一个StatefulWidget放在StatelessWidget里面
class CalendarViewWidget extends StatefulWidget {
  double height;
  //整体的背景设置
  BoxDecoration boxDecoration;

  //控制器
  final CalendarController calendarController;

  CalendarViewWidget(
      {Key key, @required this.calendarController, this.boxDecoration})
      : super(key: key);

  @override
  _CalendarViewWidgetState createState() => _CalendarViewWidgetState();
}

class _CalendarViewWidgetState extends State<CalendarViewWidget> {
  @override
  void initState() {
    //初始化一些数据，一些跟状态有关的要放到provider中
    widget.calendarController.calendarProvider.initData(
        calendarConfiguration: widget.calendarController.calendarConfiguration);

    super.initState();
  }

  @override
  void dispose() {
    widget.calendarController.clearData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CalendarProvider>.value(
      value: widget.calendarController.calendarProvider,
      child: Container(
          //外部可以自定义背景设置
          decoration: widget.boxDecoration,
          //使用const，保证外界的setState不会刷新日历这个widget
          child: CalendarContainer(widget.calendarController)),
    );
  }
}

class CalendarContainer extends StatefulWidget {
  final CalendarController calendarController;

  const CalendarContainer(this.calendarController);

  @override
  CalendarContainerState createState() => CalendarContainerState();
}

class CalendarContainerState extends State<CalendarContainer>
    with SingleTickerProviderStateMixin {
  double itemHeight;
  double totalHeight;

  bool expand;

  CalendarProvider calendarProvider;

  List<Widget> widgets = [];

  int index = 0;

  @override
  void initState() {
    calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
    expand = calendarProvider.expandStatus.value;

    if (calendarProvider.calendarConfiguration.showMode ==
        Constants.MODE_SHOW_ONLY_WEEK) {
      widgets.add(const WeekViewPager());
    } else if (calendarProvider.calendarConfiguration.showMode ==
        Constants.MODE_SHOW_WEEK_AND_MONTH) {
      widgets.add(const MonthViewPager());
      widgets.add(const WeekViewPager());
      index = 1;
    } else if (calendarProvider.calendarConfiguration.showMode ==
        Constants.MODE_SHOW_MONTH_AND_WEEK) {
      widgets.add(const MonthViewPager());
      widgets.add(const WeekViewPager());
      index = 0;
    } else {
      //默认是只显示月视图
      widgets.add(const MonthViewPager());
    }
    expand = calendarProvider.expandStatus.value;

    //如果需要视图切换的话，才需要添加监听，不然不需要监听变化
    if (calendarProvider.calendarConfiguration.showMode ==
            Constants.MODE_SHOW_WEEK_AND_MONTH ||
        calendarProvider.calendarConfiguration.showMode ==
            Constants.MODE_SHOW_MONTH_AND_WEEK) {
      calendarProvider.expandStatus.addListener(() {
        setState(() {
          print(
              "calendarProvider.expandStatus.value:${calendarProvider.expandStatus.value}");
          expand = calendarProvider.expandStatus.value;
          if (expand) {
            index = 0;
            //周视图切换到月视图
            calendarProvider.calendarConfiguration.weekController
                .jumpToPage(calendarProvider.monthPageIndex);
          } else {
            index = 1;
            //月视图切换到周视图
            calendarProvider.calendarConfiguration.weekController
                .jumpToPage(calendarProvider.weekPageIndex);
          }
        });
      });
    } else {
      index = 0;
    }

     widget.calendarController.addMonthChangeListener((year, month) {
       if (widget.calendarController.calendarProvider.calendarConfiguration
               .showMode !=
           Constants.MODE_SHOW_ONLY_WEEK) {
         //月份切换的时候，如果高度发生变化的话，需要setState使高度整体自适应
         int lineCount = DateUtil.getMonthViewLineCount(year, month);
         double newHeight = itemHeight * lineCount +
             calendarProvider.calendarConfiguration.verticalSpacing *
                 (lineCount - 1);
         if (totalHeight.toInt() != newHeight.toInt()) {
           LogUtil.log(
               TAG: this.runtimeType,
               message: "totalHeight:$totalHeight,newHeight:$newHeight");

           LogUtil.log(TAG: this.runtimeType, message: "月份视图高度发生变化");
           print("月份视图高度发生变化");
           
           setState(() {
             totalHeight = newHeight;
           });
         }
       }
     });

    //暂时先这样写死,提前计算布局的高度,不然会出现问题:a horizontal viewport was given an unlimited amount of I/flutter ( 6759): vertical space in which to expand.

    MediaQueryData mediaQueryData =
        MediaQueryData.fromWindow(WidgetsBinding.instance.window);

    //如果itemSize为空，默认是宽度/7。网页版的话是高度/7
    itemHeight = calendarProvider.calendarConfiguration.itemSize != null
        ? calendarProvider.calendarConfiguration.itemSize
        : mediaQueryData.orientation == Orientation.landscape
            ? mediaQueryData.size.height / 7
            : mediaQueryData.size.width / 7;

    calendarProvider.totalHeight = itemHeight * 6 +
        calendarProvider.calendarConfiguration.verticalSpacing * (6 - 1);

    DateTime dateTime = DateTime.now();
    int lineCount =
        DateUtil.getMonthViewLineCount(dateTime.year, dateTime.month);
    double newHeight = itemHeight * lineCount +
        calendarProvider.calendarConfiguration.verticalSpacing *
            (lineCount - 1);

    // totalHeight = newHeight;
    totalHeight = calendarProvider.totalHeight;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    LogUtil.log(TAG: this.runtimeType, message: "CalendarContainerState build");
    //暂时先这样写死,提前计算布局的高度,不然会出现问题:a horizontal viewport was given an unlimited amount of I/flutter ( 6759): vertical space in which to expand.
//    itemHeight = calendarProvider.calendarConfiguration.itemSize ??
//        MediaQuery.of(context).size.width / 7;
    return Container(
      width: itemHeight * 7,
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          /**
           * 利用const，避免每次setState都会刷新到这顶部的view
           */
          calendarProvider.calendarConfiguration.weekBarItemWidgetBuilder(),
          AnimatedContainer(
              duration: Duration(milliseconds: 500),
              height: expand ? totalHeight : itemHeight,
              child: IndexedStack(
                index: index,
                children: widgets,
              )),
        ],
      ),
    );
  }
}
