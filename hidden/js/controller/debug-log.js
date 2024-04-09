/**
 * @brief: to make get parameters at request to run debug tool
 * @param {*} timestamp : if empty --> fill ""
 * @param {*} encode_pwd
 * @param {*} options_array
 * @returns
 */
function make_GET_request_from_options(timestamp, encode_pwd, options_array) {
  let getParams = "?";
  getParams += `enpwd=${encode_pwd}`;
  getParams += `&time=${timestamp}`;
  getParams += `&info=${options_array[0]}`;
  for (var i = 1; i < options_array.length; i++) {
    getParams += `+${options_array[i]}`;
  }
  return getParams;
}

/**
 *
 * @returns all file name from /opt/intel/www/hidden/debug/output/
 */
function get_log_file() {
  return new Promise(async (resolve, reject) => {
    // Take all log file name
    try {
      const res = await hiddenHttpService.GET("/hidden/debug/output/");
      var filenames = [];
      var parser = new DOMParser();
      var doc = parser.parseFromString(res, "text/html");
      var links = doc.querySelectorAll("tr:not(.d) td.n a");
      for (const link of links) {
        var filename = link.textContent.trim();
        if (filename !== "..") {
          filenames.push(filename);
        }
      }
      resolve(filenames);
    } catch (error) {
      reject("Fail to get Log files", error);
    }
  });
}

const DEBUG_LOG_CONTROLLER = {
  fill_front_end: (data) => {
    console.log("DEBUG_LOG_CONTROLLER -- fill front end");
    // Fetch content from sub.html and insert it into the div with id "content"
    fetch("hidden/debug.html")
      .then((response) => response.text())
      .then((html) => {
        document.getElementById("Content").innerHTML = html;

        const listFileLogTable = document.getElementById("logListFile");
        const logFileTemplate = document.getElementById("logFile");
        const timestamp = document.getElementById("Timestamp");
        const timestampPattern = new RegExp(timestamp.getAttribute("pattern"));

        // action event
        var initEvent = () => {
          document
            .getElementById("select_all")
            .addEventListener("click", () => {
              if (document.getElementById("select_all").checked) {
                document
                  .getElementById("subOptions")
                  .classList.add("gemtek-switch-disabled");
              } else {
                document
                  .getElementById("subOptions")
                  .classList.remove("gemtek-switch-disabled");
              }
            });

          timestamp.addEventListener("input", () => {
            if (timestampPattern.test(timestamp.value)) {
              document
                .getElementById("timestamp_pattern_error")
                .classList.add("ng-hide");
              document.getElementById("Apply").disabled = false;
            } else {
              document.getElementById("Apply").disabled = true;
              document
                .getElementById("timestamp_pattern_error")
                .classList.remove("ng-hide");
            }
          });
        };

        // fill data
        var fillData = (fileNames) => {
          // clear current ul tag (list file)
          while (listFileLogTable.firstChild) {
            listFileLogTable.removeChild(listFileLogTable.firstChild);
          }

          // log files name to download
          for (const logFile of fileNames) {
            const li = logFileTemplate.content.cloneNode(true);

            li.querySelector(".fileName").textContent = logFile;
            li.querySelector(
              ".fileName"
            ).href = `hidden/debug/output/${logFile}`;

            listFileLogTable.appendChild(li);
          }
        };

        initEvent();
        fillData(data);

        // send request to run Debug log tool
        document.getElementById("Apply").addEventListener("click", () => {
          console.log("Run debug log");

          // init option to make get request
          const timestamp = document.getElementById("Timestamp").value;
          const encode_pwd = document.getElementById("Pwd").value;
          let options = [];
          if (document.getElementById("select_all").checked === false) {
            const suboptions = document.querySelectorAll(".sOption");
            for (var i = 0; i < suboptions.length; i++) {
              suboptions[i].checked
                ? options.push(suboptions[i].getAttribute("name"))
                : null;
            }
          }
          if (options.length == 0) options.push("");

          const getParams = make_GET_request_from_options(
            timestamp,
            encode_pwd,
            options
          );

          $("#ajaxLoaderSection").show();
          hiddenHttpService
            .GET(`/hidden/debug/debuglog.sh${getParams}`)
            .then(async (message) => {
              console.log(message);
              fillData(await get_log_file());
              $("#ajaxLoaderSection").hide();
            })
            .catch((err) => {
              console.error("Fail on run debug log", err);
              $("#ajaxLoaderSection").hide();
            });
        });
      })
      .catch((error) => console.error("Error fetching content:", error));
  },
  get_data: () => {
    console.log("DEBUG_LOG_CONTROLLER -- get_data()");
    return new Promise((resolve, reject) => {
      get_log_file()
        .then((filenames) => {
          resolve(filenames);
        })
        .catch((error) => {
          reject(error);
        });
    });
  },
  set_data: () => {},
};
