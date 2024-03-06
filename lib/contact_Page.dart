import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:daily_dial_app/userInformation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'appFunctions.dart';
import 'contactsInformation.dart';
import 'ddCategoriesPage.dart';
import 'ddLoginPage.dart';
class DDContactsPage extends StatefulWidget {
  final String mainCategory;

  const DDContactsPage({
    super.key,
    required this.mainCategory,
  });

  @override
  State<DDContactsPage> createState() => _DDContactsPageState();
}

class _DDContactsPageState extends State<DDContactsPage> {
  List<String> categoryList = [
    "Ullama",
    "Drivers",
    "Doctors",
    "Mechanic",
    "Shops",
    "Electrician",
    "Construction",
    "Social People",
  ];

  List<String> vehicleList = [
    "Car",
    "Datsan",
    "Flying Coach",
    "Tractor",
    "Coaster",
    "Suzuki",
    "Rikshaw",
    "Ambulance"
  ];
  List<String> doctorsTypesList = [
    "General Practitioner",
    "Homeopathic",
    "MBBS",
    "Medical Specialist",
    "Children Specialist",
    "ENT Specialist",
    "Dental Specialist",
    "Heart Specialist",
    "Neuro Surgeon",
    "Gynecologist",
    "Urologist",
    "Eye Specialist",
  ];
  List<String> ullamaList = [
    "Mufti",
    "Ullama-E-Kiram",
    "Qari",
    "Hafiz",
  ];
  List<String> constructionList = ["Mistri", "Mazdoor", "Plumber", "Painters"];

  List<String> shopsList = [
    "General Store",
    "Medical Store",
    "Chicken Meat Shop",
    "Beef Meat Shop",
    "Crockery And Tents",
    "Milk Shop",
    "Chef"
  ];
  List<String> socialPeople = ["SocialPeople"];
  List<String> electricianList = [
    "Residential And Domestic",
    "Automotive(Cars,Motorcycle etc)",
    "Solar Panel",
    "Refrigerator",
    "Washing Machine",
  ];
  List<String> mechanicList = [
    "Bike Mechanic",
    "Car Mechanic",
    "Tractor Mechanic",
  ];

  late Map<String, List<String>> categoryMap = {
    "Ullama": ullamaList,
    "Drivers": vehicleList,
    "Doctors": doctorsTypesList,
    "Mechanic": mechanicList,
    "Shops": shopsList,
    "Electrician": electricianList,
    "Construction": constructionList,
    "Social People": socialPeople,
  };
  late String selectedCategory = categoryList.first;
  late List<String> subCategoryList = categoryMap[selectedCategory]!;
  late String selectedSubCategory = subCategoryList.first;

  String? userId = FirebaseAuth.instance.currentUser?.uid;
  String? userRole;
  Future<void> getUserInformation() async {
    String? userId = await FirebaseAuth.instance.currentUser?.uid;
    var response = await UserInformation.collection().doc(userId).get();
    setState(() {
      userRole = response['userRole'];
    });

  }
  @override
  void initState() {
    super.initState();
    getUserInformation();
  }
  bool isLoading = false;

  final double northLatitude = 33.239155;
  final double southLatitude = 33.131839;
  final double eastLongitude = 71.032062;
  final double westLongitude = 70.786004;

  bool isLocationAllowed = false;

  Future<void> checkLocation() async {
    try {
      await Geolocator.isLocationServiceEnabled();
      await Geolocator.checkPermission();
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double currentLatitude = position.latitude;
      double currentLongitude = position.longitude;

      if (currentLatitude >= southLatitude &&
          currentLatitude <= northLatitude &&
          currentLongitude >= westLongitude &&
          currentLongitude <= eastLongitude) {
        setState(() {
          isLocationAllowed = true;
        });
      } else {
        setState(() {
          isLocationAllowed = false;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> locationPermissionRequest() async {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permission Required',textAlign: TextAlign.center,),
          content: Text(
            'To add contact this app requires access to your location. Please Turn On Location',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Request location permission
                await Geolocator.requestPermission();
                Navigator.pop(context); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );

  }



  late Future<QuerySnapshot<ContactsInformation>> contactsInfo =
  ContactsInformation.collection()
      .where('unPublished', isEqualTo: true)
      .get();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: categoryMap[widget.mainCategory]!.length,
        child: Scaffold(
          floatingActionButton: InkWell(
            onTap: () async {

              setState(() {
                isLoading=true;
              });

              var connectivityResult =
              await (Connectivity().checkConnectivity());
              if (connectivityResult == ConnectivityResult.none) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No Internet Connection. Please check your internet connection and try again.'),
                  ),
                );
                setState(() {
                  isLoading=false;
                });
                return;
              } else if (connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi) {
                bool isInternetConnected = await InternetConnectionChecker().hasConnection;
                if (!isInternetConnected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Poor internet speed. Please try again later.'),
                    ),
                  );
                  setState(() {
                    isLoading=false;
                  });
                  return;
                }
                String? userUId = await FirebaseAuth.instance.currentUser?.uid;
                if (userUId == null) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DDLoginPage()));
                }else{
                  var status = await Permission.location.status;
                  if (status.isDenied) {
                    locationPermissionRequest();
                    status = await Permission.location.status;
                    if (status.isDenied) {
                      setState(() {
                        isLoading=false;
                      });
                      return;
                    }}
                  if (userRole==null) {
                    await getUserInformation();
                  }
                  if (userRole == "Client") {
                    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
                    if (!isLocationServiceEnabled) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Location Required', textAlign: TextAlign.center),
                            content: Text(
                              'Please Turn On Location To Add Contact',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close the dialog

                                },
                                child: Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                      setState(() {
                        isLoading=false;
                      });
                      return;
                    }
                    await checkLocation();
                    if (isLocationAllowed == false) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Container(
                              height: 300,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 30,
                                  ),
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 4, right: 4),
                                      child: Text(
                                        "Sorry! The Contact Can Be Uploaded Within The Area Of Bahdurkhel Union Council.",
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.red,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 40,
                                  ),
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        setState(() {
                                          isLoading = false;
                                        });
                                      },
                                      child: Text("Ok"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DDCategoriesPage(),
                        ),
                      );
                    }
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DDCategoriesPage(),
                      ),
                    );
                  }}
                setState(() {
                  isLoading = false;
                });
              }},
            child: Container(
              height: 50,
              width: 130,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(15)),
                color: Colors.blueAccent[700],
                border: Border.all(color: Colors.black38, width: 2),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 3,
                  )
                ],
              ),
              child:isLoading==true? buildSpinkit() : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                  Text(
                    'Add Contact',
                    style: TextStyle(color: Colors.white),
                  )
                ],
              ),
            ),
          ),
          appBar: AppBar(
            toolbarHeight: 100,
            leading: Image.asset(
              "assets/Daily Dial.png",
              scale: 15,
              color: Colors.blueAccent[700],
            ),
            title: buildAppBarTitle(),
            elevation: 0.0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15)),
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            bottom: TabBar(
              tabAlignment: widget.mainCategory == "Social People"
                  ? TabAlignment.center
                  : null,
              isScrollable: true,
              indicatorColor: Colors.black,
              labelStyle: const TextStyle(fontSize: 13),
              labelColor: Colors.black,
              labelPadding: widget.mainCategory == "Social People"
                  ? null
                  : const EdgeInsets.only(right: 70),
              tabs: [
                for (int index = 0;
                index < categoryMap[widget.mainCategory]!.length;
                index++)
                  Tab(
                    child: tabsImageText(
                        widget.mainCategory == 'Drivers'
                            ? vehicleList[index]
                            : widget.mainCategory == 'Doctors'
                            ? doctorsTypesList[index]
                            : widget.mainCategory == 'Ullama'
                            ? ullamaList[index]
                            : widget.mainCategory == 'Mechanic'
                            ? mechanicList[index]
                            : widget.mainCategory == 'Shops'
                            ? shopsList[index]
                            : widget.mainCategory ==
                            'Social People'
                            ? socialPeople[index]
                            : widget.mainCategory ==
                            'Electrician'
                            ? electricianList[index]
                            : constructionList[index],
                        categoryMap[widget.mainCategory]![index]),
                  ),
              ],
            ),
          ),
          body: FutureBuilder<QuerySnapshot<ContactsInformation>>(
              future: contactsInfo,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString()),
                  );
                }
                List<ContactsInformation> contactInfoList = [];
                for (var element in snapshot.data!.docs) {
                  contactInfoList.add(element.data());
                }
                return TabBarView(children: [
                  for (int index = 0;
                  index < categoryMap[widget.mainCategory]!.length;
                  index++)
                    SubCategoryDetailScreen(
                      contactInfoList: contactInfoList,
                      subCategory: categoryMap[widget.mainCategory]![index],
                    )
                ]);
              }),
        ));
  }

  Container buildAppBarTitle() {
    return Container(
      margin: const EdgeInsets.only(right: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.mainCategory == "Ullama"
                ? "Ullama Contacts"
                : widget.mainCategory == "Drivers"
                ? "Driver Contacts"
                : widget.mainCategory == "Doctors"
                ? "Doctor Contacts"
                : widget.mainCategory == "Mechanic"
                ? "Mechanic Contacts"
                : widget.mainCategory == "Shops"
                ? "Shops Contacts"
                : widget.mainCategory == "Social People"
                ? "Social People Contacts"
                : widget.mainCategory == "Electrician"
                ? "Electrician Contacts"
                : "Construction",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          )
        ],
      ),
    );
  }

  Column tabsImageText(
      String image,
      text,
      ) {
    return Column(
      children: [
        Image.asset(
          "assets/$image.png",
          scale: 2,
        ),
        const SizedBox(
          height: 2,
        ),
        Text(text),
      ],
    );
  }
}

class SubCategoryDetailScreen extends StatelessWidget {
  const SubCategoryDetailScreen(
      {super.key, required this.contactInfoList, required this.subCategory});

  final List<ContactsInformation> contactInfoList;
  final String subCategory;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 3, right: 3, top: 10, bottom: 10),
      child: ListView.builder(
          itemCount: contactInfoList.length,
          itemBuilder: (context, index) {
            ContactsInformation contactsInformation = contactInfoList[index];
            String phoneNumber = contactsInformation.phoneNumber.toString();
            final Uri whatsApp = Uri.parse('https://wa.me/$phoneNumber');
            return contactsInformation.subCategory != subCategory
                ? Container()
                : Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black45,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 1,
                      color: Colors.black12,
                    )
                  ],
                  borderRadius:
                  const BorderRadius.all(Radius.circular(20)),
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 3,
                  color: Colors.white,
                  child: ListTile(
                    leading: contactsInformation.imageUrl != null
                        ? InkWell(
                        child: CachedNetworkImage(
                          imageUrl: contactsInformation.imageUrl!,
                          placeholder: (context, url) => CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.grey,
                            child: Image.asset(
                                'assets/ContactsAvatar.png',
                                scale: 2),
                          ),
                          errorWidget: (context, url, error) =>
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.grey,
                                child: Image.asset(
                                    'assets/ContactsAvatar.png',
                                    scale: 2),
                              ),
                          imageBuilder: (context, imageProvider) =>
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.grey,
                                backgroundImage: imageProvider,
                              ),
                        ),
                        onTap: () {
                          build_Image_Pop_UP(context, contactsInformation);
                        })
                        : CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey,
                      child: Image.asset(
                          'assets/ContactsAvatar.png',
                          scale: 2),
                    ),
                    title: Text(
                      contactsInformation.name.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    subtitle: contactsInformation.category == "Drivers"
                        ? buildDriverListTile(contactsInformation)
                        : contactsInformation.category == "Social People"
                        ? buildSocialPeopleListTile(
                        contactsInformation)
                        : buildCategoryListTile(contactsInformation),
                    trailing: Container(
                      height: 40,
                      width: 88,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          InkWell(
                            child: Image.asset(
                              "assets/whatsapp.png",
                              scale: 4,
                            ),
                            onTap: () {
                              launchUrl(whatsApp);
                            },
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          InkWell(
                            child: const Icon(
                              Icons.message,
                              color: Colors.black,
                              size: 26.5,
                            ),
                            onTap: () {
                              launchUrl(Uri.parse('sms:$phoneNumber'));
                            },
                          ),
                          const SizedBox(
                            width: 3,
                          ),
                          InkWell(
                            onTap: () {
                              callNumber(phoneNumber);
                            },
                            child: const Icon(
                              Icons.call,
                              color: Colors.black,
                              size: 26.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
    );
  }


  Column buildCategoryListTile(ContactsInformation contactsInformation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          contactsInformation.phoneNumber.toString(),
          style: const TextStyle(
            fontSize: 10,
          ),
        ),
        Text(
          contactsInformation.location.toString(),
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }

  Column buildDriverListTile(ContactsInformation contactsInformation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subCategory == 'Car'
              ? contactsInformation.vehicleName.toString()
              : contactsInformation.route.toString(),
          style: const TextStyle(
            fontSize: 10,
          ),
        ),
        Text(
          contactsInformation.phoneNumber.toString(),
          style: const TextStyle(
            fontSize: 10,
          ),
        ),
        Text(
          contactsInformation.location.toString(),
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }

  Column buildSocialPeopleListTile(ContactsInformation contactsInformation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          contactsInformation.status.toString(),
          style: const TextStyle(
            fontSize: 10,
          ),
        ),
        Text(
          contactsInformation.phoneNumber.toString(),
          style: const TextStyle(
            fontSize: 10,
          ),
        ),
        Text(
          contactsInformation.location.toString(),
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }
}
Widget buildSpinkit() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SpinKitFoldingCube(
        color: Colors.white,
        size: 15.0,
      ),
      SizedBox(width: 12,),
      Text('Please Wait ',style: TextStyle(color: Colors.white,fontSize: 10),)
    ],
  );}
