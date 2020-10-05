import 'package:minsk8/import.dart';

class SearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ExtendedAppBar(
        title: Text('Search'),
      ),
      drawer: MainDrawer('/search'),
      // тут не надо ScrollBody
      body: SafeArea(
        child: Center(
          child: Text('xxx'),
        ),
      ),
    );
  }
}
