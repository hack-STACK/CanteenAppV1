// import 'package:supabase/supabase.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class CanteenService {
//   final database = Supabase.instance.client.from('canteens');

//   Future createCanteen(canteen Newcanteen) async {
//     await database.insert(Newcanteen.toMap());
//   }

//   final stream = Supabase.instance.client.from('canteens').stream(
//     primaryKey: ['id'],
//   ).map(
//       (data) => data.map((canteenmap) => canteen.fromMap(canteenmap)).toList());

//        Future updateCanteen

// }
