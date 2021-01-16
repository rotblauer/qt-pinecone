
function api_post(end_point, send_data, params, headers, callback) {
    var xhr = new XMLHttpRequest()
    params = params || {}

    var parameters = ""
    for (var p in params) {
        parameters += "&" + p + "=" + params[p]
    }
    if (parameters.length > 0) {
        parameters = "?" + parameters;
    }
    var requestURL = end_point + parameters;
    send_data = JSON.stringify(send_data)

    xhr.onreadystatechange = function () {
        processRequest(xhr, callback)
    }

    xhr.open('POST', requestURL, true)
    xhr.setRequestHeader("Content-Type", "application/json")
    xhr.setRequestHeader("Accept", "application/json")
    for (var h in headers) {
        xhr.setRequestHeader(h, headers[h]);
    }
    xhr.send(send_data)
}

function api_get(end_point, params, callback) {
    var xhr = new XMLHttpRequest()
    params = params || {}

    var parameters = ""
    for (var p in params) {
        parameters += "&" + p + "=" + params[p]
    }
    var requestURL = end_point + "?" + parameters
    console.log(requestURL)

    xhr.onreadystatechange = function () {
        processRequest(xhr, callback)
    }

    xhr.open('GET', requestURL, true)
    xhr.setRequestHeader("Content-Type", "application/json")
    xhr.setRequestHeader("Accept", "application/json")
    xhr.send('')
}

function processRequest(xhr, callback, e) {
    if (xhr.readyState === 4) {
        var response;
        try {
            response = JSON.parse(xhr.responseText);
        } catch (ee) {
            response = xhr.responseText;
        }
        callback(xhr.status, response);
    } else if (e) {
        console.log("request error:", e);
    }
}
