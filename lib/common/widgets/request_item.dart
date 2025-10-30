import 'package:chime/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class RequestItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>)? onClick;

  const RequestItem({super.key, required this.data, this.onClick});

  @override
  Widget build(BuildContext context) {
    final CommonHelper commonHelper = CommonHelper();

    List<dynamic> logs = data['logs'];
    Map<String, dynamic>? referenceNumber = logs.where((entry) => entry['log'].contains("applied")).firstOrNull;
    Map<String, dynamic>? rejectedReason = logs.where((entry) => entry['log'].contains("rejected")).firstOrNull;

    return Container(
      height: referenceNumber != null || rejectedReason != null
          ? MediaQuery.of(context).size.height * 0.30
          : MediaQuery.of(context).size.height * 0.20,
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
      child: InkWell(
        onTap: () => onClick != null ? onClick!(data) : {},
        child: Card(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
          elevation: 2.0,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: Theme.of(context).colorScheme.primary),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: Column(
                    spacing: 10.0,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(data['shop_data']['name'] ?? "", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                          Text(
                            commonHelper.convertDateToAppDate(data['created_at']),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            spacing: 5.0,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                commonHelper.getIntlLabelSync(data['service_data']['service']['name_i18n']),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                              ),
                              Text(
                                commonHelper.getIntlLabelSync(data['service_data']['service_type']['name_i18n']),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                          Row(
                            spacing: 10.0,
                            children: [
                              InkWell(
                                onTap: () async {
                                  final Uri launchUri = Uri(scheme: 'tel', path: "${data['shop_data']['mobile_number']}");
                                  await launchUrl(launchUri);
                                },
                                child: SvgPicture.asset(commonHelper.getIconPath("ic_call.svg"), width: 28, height: 28),
                              ),
                              InkWell(
                                onTap: () async {
                                  var uri = Uri.parse(
                                    "google.navigation:q=${data['shop_data']['latitude']},${data['shop_data']['longitude']}&mode=d",
                                  );
                                  if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
                                    // ignore: use_build_context_synchronously
                                    ToastUtil.showErrorToast(context, commonHelper.getStringLabelSync("error_launch_url"));
                                  }
                                },
                                child: SvgPicture.asset(commonHelper.getIconPath("ic_direction.svg"), width: 28, height: 28),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(6.0), bottomRight: Radius.circular(6.0)),
                      color: Theme.of(context).cardColor,
                    ),
                    height: referenceNumber != null || rejectedReason != null
                        ? MediaQuery.of(context).size.height * 0.15
                        : MediaQuery.of(context).size.height * 0.065,
                    child: Column(
                      spacing: 5.0,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                              child: Text(
                                "${commonHelper.getStringLabelSync("status")} ${data['status']}",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: data['status'].toLowerCase().contains("rejected") || data['status'].toLowerCase().contains("cancelled")
                                      ? Colors.red.shade300
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: data['status'] == "rejected" || data['status'].contains("cancelled")
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            Spacer(),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(40.0), color: Theme.of(context).colorScheme.primary),
                                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                                  child: Text(
                                    "₹ ${data['service_data']['service']['total_price'] ?? ""}",
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                                  ),
                                ),
                                data.containsKey("invoice_path") && data['invoice_path'] != null
                                    ? IconButton(
                                        onPressed: () async {
                                          var uri = Uri.parse("${data['invoice_path']}");
                                          if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
                                            // ignore: use_build_context_synchronously
                                            ToastUtil.showErrorToast(context, commonHelper.getStringLabelSync("error_launch_url"));
                                          }
                                        },
                                        icon: Icon(Icons.file_download, color: Theme.of(context).colorScheme.primary),
                                      )
                                    : const SizedBox(),
                              ],
                            ),
                          ],
                        ),
                        if (referenceNumber != null || rejectedReason != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5), height: 1, thickness: 1),
                          ),
                        if (referenceNumber != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Text(
                              "${commonHelper.getStringLabelSync("reference_number")} : ${referenceNumber['log'].split(":")[1].trim()}",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                        if (rejectedReason != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: SingleChildScrollView(
                              child: Text(
                                "${commonHelper.getStringLabelSync("rejected_reason")} : ${rejectedReason['log'].split(":")[1].trim()}",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red.shade300),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
