locals {
  final = "${zipmap(data.null_data_source.merged.*.outputs.keys,
                    data.null_data_source.merged.*.outputs.values)}"
}