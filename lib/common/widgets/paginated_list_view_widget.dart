import 'package:flutter/material.dart';
import 'package:gazzer_userapp/helper/responsive_helper.dart';
import 'package:gazzer_userapp/util/dimensions.dart';
import 'package:gazzer_userapp/util/styles.dart';
import 'package:get/get.dart';

class PaginatedListViewWidget extends StatefulWidget {
  final ScrollController scrollController;
  final Function(int? offset) onPaginate;
  final int? totalSize;
  final int? offset;
  final Widget productView;
  final bool enabledPagination;
  final bool reverse;

  const PaginatedListViewWidget({
    super.key,
    required this.scrollController,
    required this.onPaginate,
    required this.totalSize,
    required this.offset,
    required this.productView,
    this.enabledPagination = true,
    this.reverse = false,
  });

  @override
  State<PaginatedListViewWidget> createState() =>
      _PaginatedListViewWidgetState();
}

class _PaginatedListViewWidgetState extends State<PaginatedListViewWidget> {
  int? _offset;
  late List<int?> _offsetList;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _offset = 1;
    _offsetList = [1];

    widget.scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    super.dispose();
    widget.scrollController.removeListener(_scrollListener);
  }

  void _scrollListener() {
    var currentIndex = widget.scrollController.position.pixels;
    var maxIndex = widget.scrollController.position.maxScrollExtent;
    if ((currentIndex >= 0.7 * maxIndex) &&
        widget.totalSize != null &&
        !_isLoading &&
        widget.enabledPagination) {
      _paginate();
    }
  }

  void _paginate() async {
    if (widget.totalSize == null) {
      debugPrint('Total size is null. Cannot paginate.');
      return;
    }

    int pageSize = (widget.totalSize! / 10).ceil();

    if (_offset! < pageSize && !_offsetList.contains(_offset! + 1)) {
      setState(() {
        _offset = _offset! + 1;
        _offsetList.add(_offset);
        _isLoading = true;
      });

      debugPrint('Paginating: Offset: $_offset, Page Size: $pageSize');
      try {
        await widget.onPaginate(_offset);
      } catch (e) {
        debugPrint('Error during pagination: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      debugPrint('No more pages to paginate or already loaded this offset.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.offset != null) {
      _offset = widget.offset;
      _offsetList = List.generate(_offset!, (index) => index + 1);
    }

    return SingleChildScrollView(
      child: Column(children: [
        widget.reverse ? const SizedBox() : widget.productView,
        (ResponsiveHelper.isDesktop(context) &&
                (widget.totalSize == null ||
                    _offset! >= (widget.totalSize! / 10).ceil() ||
                    _offsetList.contains(_offset! + 1)))
            ? const SizedBox()
            : Center(
                child: Padding(
                padding: (_isLoading || ResponsiveHelper.isDesktop(context))
                    ? const EdgeInsets.all(Dimensions.paddingSizeSmall)
                    : EdgeInsets.zero,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : (ResponsiveHelper.isDesktop(context) &&
                            widget.totalSize != null)
                        ? InkWell(
                            onTap: _paginate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: Dimensions.paddingSizeSmall,
                                  horizontal: Dimensions.paddingSizeLarge),
                              margin: ResponsiveHelper.isDesktop(context)
                                  ? const EdgeInsets.only(
                                      top: Dimensions.paddingSizeSmall)
                                  : null,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    Dimensions.radiusSmall),
                                color: Theme.of(context).primaryColor,
                              ),
                              child: Text('view_more'.tr,
                                  style: robotoMedium.copyWith(
                                      fontSize: Dimensions.fontSizeLarge,
                                      color: Colors.white)),
                            ),
                          )
                        : const SizedBox(),
              )),
        widget.reverse ? widget.productView : const SizedBox(),
      ]),
    );
  }
}
