import 'dart:isolate';
import '../domain/link_model.dart';
import 'metadata_service.dart';

void _metadataIsolateEntry(SendPort sendPort) {
  final port = ReceivePort();
  sendPort.send(port.sendPort);

  port.listen((message) async {
    if (message is List) {
      final link = message[0] as LinkModel;
      final replyPort = message[1] as SendPort;
      
      final service = MetadataService();
      final metadata = await service.fetchMetadata(link.url);
      
      replyPort.send(metadata);
    }
  });
}

Future<LinkMetadata> fetchMetadataInBackground(LinkModel link) async {
  final receivePort = ReceivePort();
  await Isolate.spawn(_metadataIsolateEntry, receivePort.sendPort);

  final sendPort = await receivePort.first as SendPort;
  final responsePort = ReceivePort();
  
  sendPort.send([link, responsePort.sendPort]);
  
  final metadata = await responsePort.first as LinkMetadata;
  return metadata;
}