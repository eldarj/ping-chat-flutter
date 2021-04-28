import 'package:flutterping/service/contact/contact.service.dart';
import 'package:flutterping/model/contact-dto.model.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:http/http.dart' as http;
import 'package:contacts_service/contacts_service.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';

class ContactService {
  static bool isSyncing = false;

  static Future<List> syncContacts(String dialCode) async {
    List result = [];

    if (!isSyncing) {
      isSyncing = true;
      result = await _sync(dialCode);
      isSyncing = false;
    }

    return result;
  }

  static Future<List> _sync(String dialCode) async {
    Iterable<Contact> contacts = await ContactsService.getContacts(
        withThumbnails: false,
        photoHighResolution: false,
        orderByGivenName: false,
        iOSLocalizedLabels: false);

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
        return [];
      }

      return response.decode();
    }

    return [];
  }
}
