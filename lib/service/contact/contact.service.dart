import 'package:flutterping/service/contact/contact.service.dart';
import 'package:flutterping/model/contact-dto.model.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:http/http.dart' as http;
import 'package:contacts_service/contacts_service.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';

class ContactService {
  static Future syncContacts(String dialCode) async {
    Iterable<Contact> contacts = await ContactsService.getContacts();

    List<ContactDto> contactDtos = [];

    contacts.forEach((contact) {
      Item mobilePhoneNumber = contact.phones.firstWhere((element) => element.label == 'mobile', orElse: () => null);

      if (mobilePhoneNumber != null
          && contact.displayName != null) {
        String displayName = contact.displayName;
        String phoneNumber = mobilePhoneNumber.value.replaceAll(" ", "");

        if (phoneNumber.startsWith("0")) {
          phoneNumber = phoneNumber.replaceFirst("0", dialCode);
        }

        if (phoneNumber.startsWith("+")) {
          contactDtos.add(new ContactDto(
              contactPhoneNumber: phoneNumber,
              contactName: displayName
          ));
        }
      }
    });

    if (contactDtos.isNotEmpty) {
      http.Response response = await HttpClientService.post('/api/contacts/sync', body: contactDtos);

      if (response.statusCode != 200) {
        throw new Exception();
      }

      return response.decode();
    }

    return [];
  }
}
