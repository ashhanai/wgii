const rewire = require("rewire");
const assert = require("chai").assert;
const sinon = require("sinon");
const index = rewire("../index.js");

const Gwei = 1000000000;
const LimitState = index.__get__("LimitState");
const price = {
	slow: 100 * Gwei,
	standard: 200 * Gwei,
	fast: 300 * Gwei,
	rapid: 400 * Gwei,
	timestamp: 1,
};


describe("Gas Price Alert", () => {
	const gasPriceAlert = index.__get__("gasPriceAlert");
	const sandbox = sinon.createSandbox();

	const fetchGasPriceStub = sandbox.stub();
	const getUserListStub = sandbox.stub();
	const notifyUserIfNeededStub = sandbox.stub();
	const adminDatabaseStub = sandbox.stub();
	const databaseRefStub = sandbox.stub();
	const refSetStub = sandbox.stub();

	const admin = { database: adminDatabaseStub };
	const database = { ref: databaseRefStub };
	const ref = { set: refSetStub };

	const fetchResponse = {
		code: 200,
		data: price,
	};

	let fetchGasPriceReset;
	let getUserListReset;
	let notifyUserIfNeededReset;
	let adminReset;
	before(() => {
		fetchGasPriceReset = index.__set__("fetchGasPrice", fetchGasPriceStub);
		getUserListReset = index.__set__("getUserList", getUserListStub);
		notifyUserIfNeededReset = index.__set__("notifyUserIfNeeded", notifyUserIfNeededStub);
		adminReset = index.__set__("admin", admin);
	});

	after(() => {
		fetchGasPriceReset();
		getUserListReset();
		notifyUserIfNeededReset();
		adminReset();
	});

	beforeEach(() => {
		fetchGasPriceStub.returns(fetchResponse);
		adminDatabaseStub.returns(database);
		databaseRefStub.returns(ref);
		getUserListStub.returns([]);
		fetchResponse.code = 200;
		fetchResponse.data = price;
	});

	afterEach(() => {
		sandbox.reset();
	});


	it("should be able to successed", async () => {
		const result = await gasPriceAlert();
		assert.equal(result, true);
	});

	it("should exit when fetch returns other than 200 status code", async () => {
		fetchResponse.code = 400;
		const result = await gasPriceAlert();
		assert.equal(result, false);
	});

	it("should exit when fetched response does not contain data object", async () => {
		fetchResponse.data = null;
		const result = await gasPriceAlert();
		assert.equal(result, false);
	});

	it("should update current price in db with fetched price", async () => {
		fetchResponse.data = {
			test: 1,
		};
		await gasPriceAlert();
		assert.equal(
			databaseRefStub.getCall(0).args[0],
			"currentPrice",
			"should get proper database reference",
		);
		assert.equal(
			refSetStub.getCall(0).args[0],
			fetchResponse.data,
			"should set fetched gas price",
		);
	});

	it("should loop over all users from db", async () => {
		const userList = ["user_1", "user_2"];
		getUserListStub.returns(userList);
		await gasPriceAlert();
		assert.equal(notifyUserIfNeededStub.callCount, userList.length);
		assert.equal(notifyUserIfNeededStub.getCall(0).args[1], userList[0]);
		assert.equal(notifyUserIfNeededStub.getCall(1).args[1], userList[1]);
	});
});


describe("Fetch Gas Price", () => {
	const fetchGasPrice = index.__get__("fetchGasPrice");
	const sandbox = sinon.createSandbox();

	const callStub = sandbox.stub();
	const bentStub = sandbox.stub();

	let bentReset;
	before(() => {
		bentReset = index.__set__("bent", bentStub);
	});

	after(() => {
		bentReset();
	});

	beforeEach(() => {
		bentStub.returns(callStub);
	});

	afterEach(() => {
		sandbox.reset();
	});


	it("should build request with correct arguments", async () => {
		await fetchGasPrice();
		const callArgs = bentStub.getCall(0).args;
		assert.equal(callArgs[0], "https://www.gasnow.org/api/v3", "should request correct host");
		assert.equal(callArgs[1], "GET", "should fetch price with GET method");
		assert.equal(callArgs[2], "json", "should use json as data format");
		assert.equal(callArgs[3], 200, "should accept only 200 status code");
	});

	it("should build request just once", async () => {
		await fetchGasPrice();
		assert(bentStub.calledOnce);
	});

	it("should call request with correct path", async () => {
		await fetchGasPrice();
		assert.equal(
			callStub.getCall(0).args[0], "/gas/price?utm_source=Wgii", "should use correct API",
		);
	});

	it("should call request just once", async () => {
		await fetchGasPrice();
		assert(callStub.calledOnce);
	});
});


describe("Get User List", () => {
	const getUserList = index.__get__("getUserList");
	const sandbox = sinon.createSandbox();

	const refOnceStub = sandbox.stub();
	const ref = { once: refOnceStub };
	const dbRefStub = sandbox.stub();
	const db = { ref: dbRefStub };

	beforeEach(() => {
		dbRefStub.returns(ref);
		refOnceStub.resolves([]);
	});

	afterEach(() => {
		sandbox.reset();
	});


	it("should refer correct data path", async () => {
		await getUserList(db);
		assert.equal(dbRefStub.getCall(0).args[0], "users");
	});

	it("should get value via once from reference", async () => {
		await getUserList(db);
		assert.equal(refOnceStub.getCall(0).args[0], "value");
	});

	it("should return user array on success from db", async () => {
		const data = ["user_1", "user_2"];
		refOnceStub.resolves(data);
		const result = await getUserList(db);
		assert.equal(result, data);
	});

	it("should return empty array on error from db", async () => {
		refOnceStub.rejects();
		const result = await getUserList(db);
		assert.equal(result.length, 0);
	});
});


describe("Notify User If Needed", () => {
	const notifyUserIfNeeded = index.__get__("notifyUserIfNeeded");
	const sandbox = sinon.createSandbox();

	const userRefUpdateStub = sandbox.stub();
	const userValStub = sandbox.stub();
	const user = {
		val: userValStub,
		ref: {
			update: userRefUpdateStub,
		},
	};

	const sendNotificationStub = sandbox.stub();
	const getLimitStateStub = sandbox.stub();

	const userVal = {
		limit: 200 * Gwei,
		lastLimitState: 1,
		deviceToken: "token",
	};

	let sendNotificationReset;
	let getLimitStateReset;
	before(() => {
		sendNotificationReset = index.__set__("sendNotification", sendNotificationStub);
		getLimitStateReset = index.__set__("getLimitState", getLimitStateStub);
	});

	after(() => {
		sendNotificationReset();
		getLimitStateReset();
	});

	beforeEach(() => {
		userVal.limit = 200 * Gwei;
		userVal.lastLimitState = LimitState.UNDER;
		userVal.deviceToken = "token";
		userValStub.returns(userVal);
		getLimitStateStub.returns(LimitState.UNDER);
	});

	afterEach(() => {
		sandbox.reset();
	});


	describe("should notify user if in correct state", () => {
		const tests = [
			/* eslint-disable max-len */
			{ args: { limitState: LimitState.UNDER, lastLimitState: LimitState.UNDER }, 	expected: false },
			{ args: { limitState: LimitState.UNDER, lastLimitState: LimitState.SLOW }, 		expected: false },
			{ args: { limitState: LimitState.UNDER, lastLimitState: LimitState.STANDARD }, 	expected: false },
			{ args: { limitState: LimitState.UNDER, lastLimitState: LimitState.FAST }, 		expected: false },
			{ args: { limitState: LimitState.UNDER, lastLimitState: LimitState.RAPID }, 	expected: false },

			{ args: { limitState: LimitState.SLOW, lastLimitState: LimitState.UNDER }, 		expected: false },
			{ args: { limitState: LimitState.SLOW, lastLimitState: LimitState.SLOW }, 		expected: false },
			{ args: { limitState: LimitState.SLOW, lastLimitState: LimitState.STANDARD }, 	expected: false },
			{ args: { limitState: LimitState.SLOW, lastLimitState: LimitState.FAST }, 		expected: false },
			{ args: { limitState: LimitState.SLOW, lastLimitState: LimitState.RAPID }, 		expected: false },

			{ args: { limitState: LimitState.STANDARD, lastLimitState: LimitState.UNDER }, 		expected: true },
			{ args: { limitState: LimitState.STANDARD, lastLimitState: LimitState.SLOW }, 		expected: true },
			{ args: { limitState: LimitState.STANDARD, lastLimitState: LimitState.STANDARD }, 	expected: false },
			{ args: { limitState: LimitState.STANDARD, lastLimitState: LimitState.FAST }, 		expected: false },
			{ args: { limitState: LimitState.STANDARD, lastLimitState: LimitState.RAPID }, 		expected: false },

			{ args: { limitState: LimitState.FAST, lastLimitState: LimitState.UNDER }, 		expected: true },
			{ args: { limitState: LimitState.FAST, lastLimitState: LimitState.SLOW }, 		expected: true },
			{ args: { limitState: LimitState.FAST, lastLimitState: LimitState.STANDARD }, 	expected: false },
			{ args: { limitState: LimitState.FAST, lastLimitState: LimitState.FAST }, 		expected: false },
			{ args: { limitState: LimitState.FAST, lastLimitState: LimitState.RAPID }, 		expected: false },

			{ args: { limitState: LimitState.RAPID, lastLimitState: LimitState.UNDER }, 	expected: true },
			{ args: { limitState: LimitState.RAPID, lastLimitState: LimitState.SLOW }, 		expected: true },
			{ args: { limitState: LimitState.RAPID, lastLimitState: LimitState.STANDARD }, 	expected: false },
			{ args: { limitState: LimitState.RAPID, lastLimitState: LimitState.FAST }, 		expected: false },
			{ args: { limitState: LimitState.RAPID, lastLimitState: LimitState.RAPID }, 	expected: false },
			/* eslint-enable max-len */
		];

		tests.forEach((test) => {
			// eslint-disable-next-line max-len
			it("should " + (test.expected ? "" : "not ") + "notify user with limit state " + test.args.limitState + " and last limit state " + test.args.lastLimitState, async () => {
				getLimitStateStub.returns(test.args.limitState);
				userVal.lastLimitState = test.args.lastLimitState;
				await notifyUserIfNeeded(price, user);
				assert.equal(sendNotificationStub.callCount, test.expected ? 1 : 0);
			});
		});
	});

	it("should notify user with correct arguments", async () => {
		getLimitStateStub.returns(LimitState.STANDARD);
		await notifyUserIfNeeded(price, user);
		const callArgs = sendNotificationStub.getCall(0).args;
		assert.equal(callArgs[0], userVal.deviceToken, "should pass correct device token");
		assert.equal(callArgs[1], userVal.limit, "should pass correct limit");
		assert.equal(callArgs[2], price.standard, "should pass standard price");
	});

	describe("should update user last limit state in db", () => {
		const tests = [
			LimitState.UNDER,
			LimitState.SLOW,
			LimitState.STANDARD,
			LimitState.FAST,
			LimitState.RAPID,
		];

		tests.forEach((limitState) => {
			it("should update " + limitState + " limit state", async () => {
				getLimitStateStub.returns(limitState);
				await notifyUserIfNeeded(price, user);
				const callArgs = userRefUpdateStub.getCall(0).args;
				assert.equal(
					callArgs[0].lastLimitState,
					limitState,
					"should update limit state with given value",
				);
				assert.equal(Object.keys(callArgs[0]).length, 1, "should update only one key");
			});
		});
	});
});


describe("Get Limit State", () => {
	const getLimitState = index.__get__("getLimitState");

	const tests = [
		/* eslint-disable max-len */
		{ args: { price: price, limit: price.slow - 10 }, 		expected: LimitState.UNDER, 	describe: "below safe" },
		{ args: { price: price, limit: price.slow }, 			expected: LimitState.SLOW, 		describe: "equal safe" },
		{ args: { price: price, limit: price.standard - 10 }, 	expected: LimitState.SLOW, 		describe: "above safe but below propose" },
		{ args: { price: price, limit: price.standard }, 		expected: LimitState.STANDARD, 	describe: "equal propose" },
		{ args: { price: price, limit: price.fast - 10 }, 		expected: LimitState.STANDARD, 	describe: "above propose but below fast" },
		{ args: { price: price, limit: price.fast }, 			expected: LimitState.FAST, 		describe: "equal fast" },
		{ args: { price: price, limit: price.rapid - 10 }, 		expected: LimitState.FAST, 		describe: "above fast but below rapid" },
		{ args: { price: price, limit: price.rapid }, 			expected: LimitState.RAPID, 	describe: "equal rapid" },
		{ args: { price: price, limit: price.rapid + 10 }, 		expected: LimitState.RAPID, 	describe: "above rapid" },
		/* eslint-enable max-len */
	];

	tests.forEach((test) => {
		it("should return limit state " + test.expected + " for limit " + test.describe, () => {
			const state = getLimitState(test.args.price, test.args.limit);
			assert.equal(state, test.expected);
		});
	});
});


describe("Send Notification", () => {
	const sendNotification = index.__get__("sendNotification");
	const sandbox = sinon.createSandbox();

	const sendToDeviceSpy = sandbox.spy();
	const messaging = { sendToDevice: sendToDeviceSpy };
	const messagingFake = sandbox.fake.returns(messaging);
	const admin = { messaging: messagingFake };

	let adminReset;
	before(() => {
		adminReset = index.__set__("admin", admin);
	});

	after(() => {
		adminReset();
	});

	afterEach(() => {
		sandbox.reset();
	});

	const limit = 200 * Gwei;
	const price = 250 * Gwei;
	const correctPayload = {
		notification: {
			title: "Gas Price Alert",
			body: "Gas price reached your limit 250 and is 200 now 🤩🎉",
		},
	};


	it("should call admin messaging send to device function with correct arguments", async () => {
		const token = "token";
		await sendNotification(token, price, limit);
		assert(sendToDeviceSpy.calledOnce, "should send notification just once");
		assert(sendToDeviceSpy.calledWith(token, correctPayload), "should pass correct arguments");
	});

	it("should not call admin messaging send to device function when token is empty", async () => {
		await sendNotification("", price, limit);
		assert(sendToDeviceSpy.notCalled, "should not send notification");
	});

	it("shoud not call admin messaging send to device function when token is null", async () => {
		await sendNotification(null, price, limit);
		assert(sendToDeviceSpy.notCalled, "should not send notification");
	});
});


describe("Get Gwei", () => {
	const getGwei = index.__get__("getGwei");
	const tests = [
		{ args: { wei: 1000000000 }, 	expected: 1 },
		{ args: { wei: 0 }, 			expected: 0 },
		{ args: { wei: 1400000000 }, 	expected: 1 },
		{ args: { wei: 1500000000 }, 	expected: 2 },
		{ args: { wei: 1900000000 }, 	expected: 2 },
		{ args: { wei: 500000000 }, 	expected: 1 },
		{ args: { wei: 450000000 }, 	expected: 0.45 },
		{ args: { wei: 400000000 }, 	expected: 0.4 },
		{ args: { wei: 123000000000 }, 	expected: 123 },
		{ args: { wei: 40000000 }, 		expected: 0.04 },
		{ args: { wei: 400000 }, 		expected: 0.0004 },
		{ args: { wei: 4000 }, 			expected: 0.000004 },
		{ args: { wei: 40 }, 			expected: 0.00000004 },
		{ args: { wei: 4 }, 			expected: 0.000000004 },
	];

	tests.forEach((test) => {
		it("should return " + test.expected + " gwei for " + test.args.wei + " wei", () => {
			const gwei = getGwei(test.args.wei);
			assert.equal(gwei, test.expected);
		});
	});
});
