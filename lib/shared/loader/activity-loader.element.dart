import 'package:flutter/material.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:shimmer/shimmer.dart';

class ActivityLoader {
  static Center build() {
    return Center(
      child: Spinner(),
    );
  }

  static Widget shimmer({ Widget child }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: child ?? Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static Widget contactsShimmer() {
    return Column(children: [
      Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(
          child: Column(
            children: [
              buildContactShimmer(),
              buildContactShimmer(),
              buildContactShimmer(),
            ],
          ),
        ),
      ),
      Shimmer.fromColors(
        baseColor: Colors.grey.shade100,
        highlightColor: Colors.grey.shade50,
        child: Container(
          child: Column(
            children: [
              buildContactShimmer(),
            ],
          ),
        ),
      )
    ]);
  }

  static buildContactShimmer() {
    return Container(
      padding: EdgeInsets.all(12.5),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            margin: EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
              child: Container(
                  margin: EdgeInsets.only(right: 25),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(height: 15, color: Colors.white, margin: EdgeInsets.only(bottom: 5)),
                    Container(width: 90, height: 15, color: Colors.white),
                  ])
              )
          ),
          Container(width: 80, height: 15, color: Colors.white)
        ],
      ),
    );
  }
}
