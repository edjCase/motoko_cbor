import Text "mo:base/Text";
import Matchers "mo:matchers/Matchers";
import T "mo:matchers/Testable";
import Suite "mo:matchers/Suite";

let equals10 = Matchers.equals(T.nat(10));
let equals20 = Matchers.equals(T.nat(20));
let greaterThan10: Matchers.Matcher<Nat> = Matchers.greaterThan(10);
let greaterThan20: Matchers.Matcher<Nat> = Matchers.greaterThan(20);

let suite = Suite.suite("CborReader", [
    Suite.test("Described as", 20, Matchers.describedAs("20's a lot mate.", equals10)),  
]);

Suite.run(suite)