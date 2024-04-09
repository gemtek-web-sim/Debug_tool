// https://192.168.18.1/cgi/cgi_get?Object=Device.DeviceInfo&Manufacturer=&SerialNumber=&SoftwareVersion=&ModelName=&HardwareVersion=

const getUrls = {
  Wifi: [
    "/cgi/cgi_get_filterbyfirstparamval?Object=Device.WiFi.SSID&LowerLayers=Device.WiFi.Radio.1.&SSID=", // 2.4GHz -- SSID
    "/cgi/cgi_get_filterbyfirstparamval?Object=Device.WiFi.SSID&LowerLayers=Device.WiFi.Radio.2.&SSID=", // 5GHz -- SSID
    "/cgi/cgi_get_subobjvals?Object=Device.WiFi.AccessPoint.*.Security", // Security wifi
  ],
  SysInfo: [
    "/cgi/cgi_get?Object=Device.DeviceInfo&SerialNumber=", // Serial Number
    "/cgi/cgi_get?Object=Device.Time", // Timestamp
  ],

  DeviceStatus: [
    "/cgi/cgi_get?Object=Device.IP.Interface&X_GTK_DefaultGateway=true", // Internet Status, Protocol
  ],
};
// Device.IP.Interface.*.X_GTK_InternetStatus

const DEVICE_INFO_CONTROLLER = {
  fill_front_end: (data) => {
    console.log("DEVICE_INFO_CONTROLLER -- fill_front_end()");
    // Fetch content from sub.html and insert it into the div with id "content"
    fetch("hidden/device-info.html")
      .then((response) => response.text())
      .then((html) => {
        document.getElementById("Content").innerHTML = html;
        const wifiListTable = document.getElementById("bodyData");
        const tableElemTemplate = document.getElementById("wifiElem");

        console.log("Data to fill: ", data);
        // Fill wifi 2.4GHz
        for (var i = 0; i < data.Wifi[0].length; i++) {
          const tr = tableElemTemplate.content.cloneNode(true);

          tr.querySelector(".SSID").textContent =
            data.Wifi[0][i].Param[0].ParamValue;
          tr.querySelector(".Radio").textContent = "2.4GHz";
          tr.querySelector(".Security").textContent =
            data.Wifi[2][i].Param[4].ParamValue;

          wifiListTable.appendChild(tr);
        }

        // Fill wifi 5GHz
        var secu5startIndex = data.Wifi[0].length;
        for (var i = 0; i < data.Wifi[1].length; i++) {
          const tr = tableElemTemplate.content.cloneNode(true);

          tr.querySelector(".SSID").textContent =
            data.Wifi[1][i].Param[0].ParamValue;
          tr.querySelector(".Radio").textContent = "5GHz";
          tr.querySelector(".Security").textContent =
            data.Wifi[2][i + secu5startIndex].Param[4].ParamValue;

          wifiListTable.appendChild(tr);
        }

        // System Info
        document.getElementById("SerialNumber").textContent =
          data.SysInfo[0][0].Param[0].ParamValue; // SerialNumber
        document.getElementById("Timestamp").textContent =
          data.SysInfo[1][0].Param[6].ParamValue; // CurrentLocalTime

        // Device Status
        document.getElementById("statusText").textContent =
          data.DeviceStatus[0][0].Param[9].ParamValue; // X_GTK_InternetStatus
        console.log(
          "Internet Status: ",
          data.DeviceStatus[0][0].Param[9].ParamValue
        );
        if (document.getElementById("statusText").textContent == "Up") {
          document.getElementById("InternetAddress").textContent =
            data.DeviceStatus[0][1].Param[0].ParamValue;
          document.getElementById("DefaultGateway").textContent =
            data.DeviceStatus[0][1].Param[2].ParamValue;
          document.getElementById("SubnetMask").textContent =
            data.DeviceStatus[0][1].Param[1].ParamValue;
          document
            .getElementById("statusIcon")
            .classList.add("gemtek-status-up");
        } else {
          document
            .getElementById("statusIcon")
            .classList.add("gemtek-status-down");

          document.getElementById("Protocol").textContent =
            data.DeviceStatus[0][1].Param[0].ParamValue; // AddressingType
          document.getElementById("MacAddress").textContent =
            data.DeviceStatus[1][0].Param[4].ParamValue; // MACAddress
        }
      })
      .catch((error) => console.error("Error fetching content:", error));
  },
  get_data: () => {
    console.log("DEVICE_INFO_CONTROLLER -- get_data()");
    let totalData = {}; // reset totalData
    return new Promise(async (resolve, reject) => {
      for (const category in getUrls) {
        const urlArray = getUrls[category];

        totalData[category] = [];
        for (const url of urlArray) {
          try {
            const res = await hiddenHttpService.GET(url);
            totalData[category].push(res.Objects);
          } catch (error) {
            reject(error);
          }
        }
      }

      // Get MAC address
      const splitObjName = totalData.DeviceStatus[0][0].ObjName.split(".");
      const moreUrls = [
        `/cgi/cgi_get?Object=Device.Ethernet.Link.${splitObjName[3].toString()}`, // MAC address
      ];

      for (const url of moreUrls) {
        try {
          const res = await hiddenHttpService.GET(url);
          totalData.DeviceStatus.push(res.Objects);
        } catch (error) {
          reject(error);
        }
      }
      resolve(totalData);
    });
  },
  set_data: () => {},
};
