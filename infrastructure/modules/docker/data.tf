data "docker_registry_image" "images" {
  count = "${length(keys(var.images))}"
  name  = "${element(values(var.images), count.index)}"
}

data "null_data_source" "merged" {
  count = "${length(keys(var.images))}"
  inputs = {
    keys   = "${element(keys(var.images), count.index)}"
    values = "${join("@",
                    list(
                      element(split(":", element(data.docker_registry_image.images.*.name, count.index)), 0),
                      element(data.docker_registry_image.images.*.sha256_digest, count.index)
                    )
              )}"
  }
}
