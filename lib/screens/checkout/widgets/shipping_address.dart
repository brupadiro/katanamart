import 'package:collection/collection.dart' show IterableExtension;
import 'package:country_pickers/country_pickers.dart' as picker;
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';
import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../generated/l10n.dart';
import '../../../models/index.dart' show Address, CartModel, Country, UserModel;
import '../../../services/index.dart';
import '../../../widgets/common/common_safe_area.dart';
import '../../../widgets/common/flux_image.dart';
import '../../../widgets/common/place_picker.dart';
import '../choose_address_screen.dart';

class ShippingAddress extends StatefulWidget {
  final Function? onNext;

  const ShippingAddress({this.onNext});

  @override
  State<ShippingAddress> createState() => _ShippingAddressState();
}

class _ShippingAddressState extends State<ShippingAddress> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _blockController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();

  final _lastNameNode = FocusNode();
  final _phoneNode = FocusNode();
  final _emailNode = FocusNode();
  final _cityNode = FocusNode();
  final _streetNode = FocusNode();
  final _blockNode = FocusNode();
  final _zipNode = FocusNode();
  final _stateNode = FocusNode();
  final _countryNode = FocusNode();
  final _apartmentNode = FocusNode();

  Address? address;
  List<Country> countries = [
    Country(
      code: "es",
      name: "Spain",
    ),
    Country(
      code: "it",
      name: "Italy",
    ),
    Country(
      code: "gb",
      name: "United Kingdom",
    ),
    Country(
      code: "de",
      name: "Germany",
    ),
    Country(
      code: "fr",
      name: "France",
    ),
  ];
  List<dynamic> states = [];

  @override
  void dispose() {
    _cityController.dispose();
    _streetController.dispose();
    _blockController.dispose();
    _zipController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _apartmentController.dispose();

    _lastNameNode.dispose();
    _phoneNode.dispose();
    _emailNode.dispose();
    _cityNode.dispose();
    _streetNode.dispose();
    _blockNode.dispose();
    _zipNode.dispose();
    _stateNode.dispose();
    _countryNode.dispose();
    _apartmentNode.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration.zero,
      () async {
        final addressValue =
            await Provider.of<CartModel>(context, listen: false).getAddress();
        // ignore: unnecessary_null_comparison
        if (addressValue != null) {
          setState(() {
            address = addressValue;
            _cityController.text = address?.city ?? '';
            _streetController.text = address?.street ?? '';
            _zipController.text = address?.zipCode ?? '';
            _stateController.text = address?.state ?? '';
            _blockController.text = address?.block ?? '';
            _apartmentController.text = address?.apartment ?? '';
          });
        } else {
          var user = Provider.of<UserModel>(context, listen: false).user;
          setState(() {
            address = Address(country: kPaymentConfig.defaultCountryISOCode);
            if (kPaymentConfig.defaultStateISOCode != null) {
              address!.state = kPaymentConfig.defaultStateISOCode;
            }
            _countryController.text = address!.country!;
            _stateController.text = address!.state!;
            if (user != null) {
              address!.firstName = user.firstName;
              address!.lastName = user.lastName;
              address!.email = user.email;
            }
          });
        }
        var country = countries.firstWhereOrNull((element) =>
            element.id == address!.country || element.code == address!.country);
        if (country == null) {
          if (countries.isNotEmpty) {
            country = countries[0];
            address!.country = countries[0].name;
          } else {
            country = Country.fromConfig(address!.country, null, null, []);
          }
        } else {
          address!.country = country.code;
          address!.countryId = country.id;
        }
        _countryController.text = country.code!;
        if (mounted) {
          setState(() {});
        }
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Future<void> updateState(Address? address) async {
    setState(() {
      _cityController.text = address?.city ?? '';
      _streetController.text = address?.street ?? '';
      _zipController.text = address?.zipCode ?? '';
      _stateController.text = address?.state ?? '';
      _countryController.text = address?.country ?? '';
      this.address?.country = address?.country ?? '';
      _apartmentController.text = address?.apartment ?? '';
      _blockController.text = address?.block ?? '';
    });
  }

  bool checkToSave() {
    final storage = LocalStorage(LocalStorageKey.address);
    var listAddress = <Address>[];
    try {
      var data = storage.getItem('data');
      if (data != null) {
        for (var item in (data as List)) {
          final add = Address.fromLocalJson(item);
          listAddress.add(add);
        }
      }
      for (var local in listAddress) {
        if (local.city != _cityController.text) continue;
        if (local.street != _streetController.text) continue;
        if (local.zipCode != _zipController.text) continue;
        if (local.state != _stateController.text) continue;
        showDialog(
          context: context,
          useRootNavigator: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(S.of(context).yourAddressExistYourLocal),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    S.of(context).ok,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                )
              ],
            );
          },
        );
        return false;
      }
    } catch (err) {
      printLog(err);
    }
    return true;
  }

  Future<void> saveDataToLocal() async {
    final storage = LocalStorage(LocalStorageKey.address);
    var listAddress = <Address?>[];
    listAddress.add(address);
    try {
      final ready = await storage.ready;
      if (ready) {
        var data = storage.getItem('data');
        if (data != null) {
          var listData = data as List;
          for (var item in listData) {
            final add = Address.fromLocalJson(item);
            listAddress.add(add);
          }
        }
        await storage.setItem(
            'data',
            listAddress.map((item) {
              return item!.toJsonEncodable();
            }).toList());
        await showDialog(
          context: context,
          useRootNavigator: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(S.of(context).youHaveBeenSaveAddressYourLocal),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    S.of(context).ok,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                )
              ],
            );
          },
        );
      }
    } catch (err) {
      printLog(err);
    }
  }

  String? validateEmail(String email) {
    if (email.isEmail) {
      return null;
    }
    return 'The E-mail Address must be a valid email address.';
  }

  var countryName = "Spain";
  @override
  Widget build(BuildContext context) {
    if (address == null) {
      return SizedBox(height: 100, child: kLoadingWidget(context));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextFormField(
                        autocorrect: false,
                        initialValue: address!.firstName,
                        autofillHints: const [AutofillHints.givenName],
                        decoration:
                            InputDecoration(labelText: S.of(context).firstName),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (val) {
                          return val!.isEmpty
                              ? S.of(context).firstNameIsRequired
                              : null;
                        },
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_lastNameNode),
                        onSaved: (String? value) {
                          address!.firstName = value;
                        },
                      ),
                      TextFormField(
                        autocorrect: false,
                        initialValue: address!.lastName,
                        autofillHints: const [AutofillHints.familyName],
                        focusNode: _lastNameNode,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (val) {
                          return val!.isEmpty
                              ? S.of(context).lastNameIsRequired
                              : null;
                        },
                        decoration:
                            InputDecoration(labelText: S.of(context).lastName),
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_phoneNode),
                        onSaved: (String? value) {
                          address!.lastName = value;
                        },
                      ),
                      TextFormField(
                        autocorrect: false,
                        initialValue: address!.phoneNumber,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        focusNode: _phoneNode,
                        decoration: InputDecoration(
                          labelText: S.of(context).phoneNumber,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (val) {
                          return val!.isEmpty
                              ? S.of(context).phoneIsRequired
                              : null;
                        },
                        keyboardType: TextInputType.number,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_emailNode),
                        onSaved: (String? value) {
                          address!.phoneNumber = value;
                        },
                      ),
                      TextFormField(
                        autocorrect: false,
                        initialValue: address!.email,
                        autofillHints: const [AutofillHints.email],
                        focusNode: _emailNode,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: S.of(context).email,
                        ),
                        textInputAction: TextInputAction.done,
                        validator: (val) {
                          if (val!.isEmpty) {
                            return S.of(context).emailIsRequired;
                          }
                          return validateEmail(val);
                        },
                        onSaved: (String? value) {
                          address!.email = value;
                        },
                      ),
                      const SizedBox(height: 10.0),
                      if (kPaymentConfig.allowSearchingAddress &&
                          kGoogleApiKey.isNotEmpty)
                        Row(
                          children: [
                            Expanded(
                              child: ButtonTheme(
                                height: 60,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0.0,
                                    onPrimary:
                                        Theme.of(context).colorScheme.secondary,
                                    primary:
                                        Theme.of(context).primaryColorLight,
                                  ),
                                  onPressed: () async {
                                    final result =
                                        await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => PlacePicker(
                                          kIsWeb
                                              ? kGoogleApiKey.web
                                              : isIos
                                                  ? kGoogleApiKey.ios
                                                  : kGoogleApiKey.android,
                                        ),
                                      ),
                                    );

                                    if (result is LocationResult) {
                                      address!.country = result.country;
                                      address!.street = result.street;
                                      address!.state = result.state;
                                      address!.city = result.city;
                                      address!.zipCode = result.zip;
                                      if (result.latLng?.latitude != null &&
                                          result.latLng?.latitude != null) {
                                        address!.mapUrl =
                                            'https://maps.google.com/maps?q=${result.latLng?.latitude},${result.latLng?.longitude}&output=embed';
                                        address!.latitude =
                                            result.latLng?.latitude.toString();
                                        address!.longitude =
                                            result.latLng?.longitude.toString();
                                      }

                                      setState(() {
                                        _cityController.text =
                                            address!.city ?? '';
                                        _stateController.text =
                                            address!.state ?? '';
                                        _streetController.text =
                                            address!.street ?? '';
                                        _zipController.text =
                                            address!.zipCode ?? '';
                                        _countryController.text =
                                            address!.country ?? '';
                                      });
                                      setState(() {});
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      const Icon(
                                        CupertinoIcons.arrow_up_right_diamond,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10.0),
                                      Text(S
                                          .of(context)
                                          .searchingAddress
                                          .toUpperCase()),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 10),
                      ButtonTheme(
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0.0,
                            onPrimary: Theme.of(context).colorScheme.secondary,
                            primary: Theme.of(context).primaryColorLight,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChooseAddressScreen(updateState),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Icon(
                                CupertinoIcons.person_crop_square,
                                size: 16,
                              ),
                              const SizedBox(width: 10.0),
                              Text(
                                S.of(context).selectAddress.toUpperCase(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        S.of(context).country,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: _openCountryPickerDialog,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(_countryController.text,
                                        style: const TextStyle(fontSize: 17.0)),
                                  ),
                                  const Icon(Icons.arrow_drop_down)
                                ],
                              ),
                            ),
                            const Divider(
                              height: 1,
                              color: kGrey900,
                            )
                          ],
                        ),
                      ),
                      TextFormField(
                        autocorrect: false,
                        controller: _stateController,
                        focusNode: _stateNode,
                        validator: (val) {
                          return val!.isEmpty
                              ? S.of(context).stateIsRequired
                              : null;
                        },
                        decoration:
                            InputDecoration(labelText: S.of(context).state),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_cityNode),
                        onSaved: (String? value) {
                          address!.state = value;
                        },
                      ),
                      TextFormField(
                        autocorrect: false,
                        controller: _cityController,
                        autofillHints: const [AutofillHints.addressCity],
                        focusNode: _cityNode,
                        validator: (val) {
                          return val!.isEmpty
                              ? S.of(context).cityIsRequired
                              : null;
                        },
                        decoration:
                            InputDecoration(labelText: S.of(context).city),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_apartmentNode),
                        onSaved: (String? value) {
                          address!.city = value;
                        },
                      ),
                      TextFormField(
                        autocorrect: false,
                        controller: _apartmentController,
                        focusNode: _apartmentNode,
                        validator: (val) {
                          return null;
                        },
                        decoration: InputDecoration(
                            labelText: S.of(context).streetNameApartment),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_blockNode),
                        onSaved: (String? value) {
                          address!.apartment = value;
                        },
                      ),
                      TextFormField(
                        autocorrect: false,
                        controller: _blockController,
                        focusNode: _blockNode,
                        validator: (val) {
                          return null;
                        },
                        decoration: InputDecoration(
                            labelText: S.of(context).streetNameBlock),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_streetNode),
                        onSaved: (String? value) {
                          address!.block = value;
                        },
                      ),
                      TextFormField(
                        autocorrect: false,
                        controller: _streetController,
                        autofillHints: const [AutofillHints.fullStreetAddress],
                        focusNode: _streetNode,
                        validator: (val) {
                          return val!.isEmpty
                              ? S.of(context).streetIsRequired
                              : null;
                        },
                        decoration: InputDecoration(
                            labelText: S.of(context).streetName),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_zipNode),
                        onSaved: (String? value) {
                          address!.street = value;
                        },
                      ),
                      TextFormField(
                        autocorrect: false,
                        controller: _zipController,
                        autofillHints: const [AutofillHints.postalCode],
                        focusNode: _zipNode,
                        validator: (val) {
                          return val!.isEmpty
                              ? S.of(context).zipCodeIsRequired
                              : null;
                        },
                        keyboardType: kPaymentConfig.enableAlphanumericZipCode
                            ? TextInputType.text
                            : TextInputType.number,
                        textInputAction: TextInputAction.done,
                        decoration:
                            InputDecoration(labelText: S.of(context).zipCode),
                        onSaved: (String? value) {
                          address!.zipCode = value;
                        },
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildBottom(),
      ],
    );
  }

  Widget _buildBottom() {
    return CommonSafeArea(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 150,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () {
                if (!checkToSave()) return;
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  Provider.of<CartModel>(context, listen: false)
                      .setAddress(address);
                  saveDataToLocal();
                }
              },
              icon: const Icon(
                CupertinoIcons.plus_app,
                size: 20,
              ),
              label: Text(
                S.of(context).saveAddress.toUpperCase(),
                style: Theme.of(context).textTheme.caption!.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ),
          ),
          Container(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: 0.0,
                onPrimary: Colors.white,
                primary: Theme.of(context).primaryColor,
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(
                Icons.local_shipping_outlined,
                size: 18,
              ),
              onPressed: _onNext,
              label: Text(
                (kPaymentConfig.enableShipping
                        ? S.of(context).continueToShipping
                        : kPaymentConfig.enableReview
                            ? S.of(context).continueToReview
                            : S.of(context).continueToPayment)
                    .toUpperCase(),
                style: Theme.of(context)
                    .textTheme
                    .caption!
                    .copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Load Shipping beforehand
  void _loadShipping({bool beforehand = true}) {
    Services().widget.loadShippingMethods(
        context, Provider.of<CartModel>(context, listen: false), beforehand);
  }

  /// on tap to Next Button
  void _onNext() {
    {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();
        Provider.of<CartModel>(context, listen: false).setAddress(address);
        _loadShipping(beforehand: false);
        widget.onNext!();
      }
    }
  }

  Widget renderStateInput() {
    if (states.isNotEmpty) {
      var items = <DropdownMenuItem>[];
      for (var item in states) {
        items.add(
          DropdownMenuItem(
            value: item.id,
            child: Text(item.name),
          ),
        );
      }
      String? value;

      return DropdownButton(
        items: items,
        value: value,
        onChanged: (dynamic val) {
          setState(() {
            address!.state = val;
          });
        },
        isExpanded: true,
        itemHeight: 70,
        hint: Text(S.of(context).stateProvince),
      );
    } else {
      return TextFormField(
        autocorrect: false,
        controller: _stateController,
        autofillHints: const [AutofillHints.addressState],
        validator: (val) {
          return val!.isEmpty ? S.of(context).streetIsRequired : null;
        },
        decoration: InputDecoration(labelText: S.of(context).stateProvince),
        onSaved: (String? value) {
          address!.state = value;
        },
      );
    }
  }

  void _openCountryPickerDialog() => showDialog(
        context: context,
        useRootNavigator: false,
        builder: (contextBuilder) => Dialog(
          child: SingleChildScrollView(
            child: Column(
              children: List.generate(
                countries.length,
                (index) {
                  return GestureDetector(
                    onTap: () async {
                      setState(() {
                        _countryController.text = countries[index].name!;
                        address!.country = countries[index].name;
                        address!.countryId = countries[index].id;
                      });
                      Navigator.pop(contextBuilder);
                      setState(() {});
                    },
                    child: ListTile(
                      leading: Image.asset(
                        'assets/images/country/${countries[index].code}.png',
                        width: 30,
                        height: 20,
                        fit: BoxFit.cover,
                      ),
                      title: Text(countries[index].name!),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
}
