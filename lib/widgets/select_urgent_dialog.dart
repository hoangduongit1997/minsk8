import 'package:flutter/material.dart';
import 'package:minsk8/import.dart';

// TODO: CheckboxListTile

Future<UrgentStatus> selectUrgentDialog(
    BuildContext context, UrgentStatus selected) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(height: 32),
            Text(
              'Как срочно надо отдать?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 16),
            ListBox(
              itemCount: kUrgents.length,
              itemBuilder: (BuildContext context, int index) {
                return Material(
                  color: selected == kUrgents[index].value
                      ? Colors.grey.withOpacity(0.2)
                      : Colors.white,
                  child: InkWell(
                    child: ListTile(
                      title: Text(kUrgents[index].name),
                      subtitle: Text(kUrgents[index].text),
                      // selected: selected == urgents[index].value,
                      trailing: selected == kUrgents[index].value
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(4),
                                ),
                              ),
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.check,
                                color: Colors.red,
                                size: kButtonIconSize,
                              ),
                            )
                          : null,
                      dense: true,
                    ),
                    onLongPress: () {}, // чтобы сократить время для splashColor
                    onTap: () {
                      Navigator.of(context).pop(kUrgents[index].value);
                    },
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return SizedBox(height: 8);
              },
            ),
            SizedBox(height: 32),
          ],
        ),
      );
    },
  );
}
