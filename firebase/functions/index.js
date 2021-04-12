const functions = require("firebase-functions");
const bent = require("bent");
const admin = require("firebase-admin");
const express = require("express");
const cors = require("cors");

const serviceAccount = require("./.private/wgii-f3370-firebase-adminsdk-buwys-5a9a73bc72.json");
admin.initializeApp({
	credential: admin.credential.cert(serviceAccount),
	databaseURL: "https://wgii-f3370-default-rtdb.europe-west1.firebasedatabase.app",
});

const app = express();
app.use(cors({ origin: true }));

const LimitState = {
	UNDER: 1,
	SLOW: 2,
	STANDARD: 3,
	FAST: 4,
	RAPID: 5,
};

const Gwei = 1000000000;


async function gasPriceAlert() {
	const res = await fetchGasPrice();
	if (res.code != 200) {
		console.log("Fetch ended with other than 200 status code: " + res.code);
		return false;
	}

	if (res.data == null) {
		console.log("Fetched response does not contain data object with gas prices.");
		return false;
	}

	const db = admin.database();
	const price = res.data;

	console.log("Updating current price:");
	console.log(price);
	await db.ref("currentPrice").set(price);

	const users = await getUserList(db);

	users.forEach((user) => {
		notifyUserIfNeeded(price, user);
	});

	return true;
}

async function fetchGasPrice() {
	const etherscan = bent("https://www.gasnow.org/api/v3", "GET", "json", 200);
	return await etherscan("/gas/price?utm_source=Wgii");
}

async function getUserList(db) {
	const usersRef = db.ref("users");
	return await usersRef.once("value").catch((error) => {
		return [];
	});
}

async function notifyUserIfNeeded(price, user) {
	const limit = user.val().limit;
	const lastLimitState = user.val().lastLimitState;
	const limitState = getLimitState(price, limit);

	if (limitState >= LimitState.STANDARD && lastLimitState < LimitState.STANDARD) {
		await sendNotification(user.val().deviceToken, limit, price.standard);
	}

	await user.ref.update({
		lastLimitState: limitState,
	});
}

function getLimitState(price, limit) {
	if (limit < price.slow) {
		return LimitState.UNDER;
	}
	if (limit >= price.slow && limit < price.standard) {
		return LimitState.SLOW;
	}
	if (limit >= price.standard && limit < price.fast) {
		return LimitState.STANDARD;
	}
	if (limit >= price.fast && limit < price.rapid) {
		return LimitState.FAST;
	}
	return LimitState.RAPID;
}

async function sendNotification(token, limit, price) {
	if (!token) {
		return;
	}

	const gweiLimit = getGwei(limit);
	const gweiPrice = getGwei(price);
	const payload = {
		notification: {
			title: "Gas Price Alert",
			body: "Gas price reached your limit " + gweiLimit + " and is " + gweiPrice + " now 🤩🎉",
		},
	};
	await admin.messaging().sendToDevice(token, payload);
}

function getGwei(wei) {
	const gwei = wei / Gwei;
	const rounded = Math.round(gwei);
	if (rounded > 0) {
		return rounded;
	}
	return gwei;
}


exports.gasPriceAlert = functions
	.region("europe-west1")
	.pubsub
	.schedule("* * * * *")
	.timeZone("Europe/Prague")
	.onRun((context) => {
		gasPriceAlert();
		return null;
	});
