local comparisonOperatorHelper = require("ComparisonOperatorHelper")

local function ComparisonOperatorHelperTest_evaluate()
	assert( comparisonOperatorHelper.evaluate("Equals", false, false, "test1", "test1",nil) )
	assert( comparisonOperatorHelper.evaluate("Equals", false, false, "test1", "Test1",nil) == false )
	assert( comparisonOperatorHelper.evaluate("Equals", false, true, "test1", "Test1",nil) )
	assert( comparisonOperatorHelper.evaluate("Equals", true, false, "test1", "Test1",nil) )
	assert( comparisonOperatorHelper.evaluate("Equals", true, false, "test1", "test1",nil) == false )
	assert( comparisonOperatorHelper.evaluate("Equals", true, true, "test1", "Test1",nil) == false )

	assert( comparisonOperatorHelper.evaluate("Contains", false, false, "test_test1_test", "test1",nil) )
	assert( comparisonOperatorHelper.evaluate("Contains",false, false, "test_test1_test", "Test1",nil) == false )
	assert( comparisonOperatorHelper.evaluate("Contains",false, true, "test_test1_test", "Test1",nil) )
	assert( comparisonOperatorHelper.evaluate("Contains", true, false, "test_test1_test", "Test1",nil) )
	assert( comparisonOperatorHelper.evaluate("Contains",true, true, "test_test1", "Test1",nil) == false )
	assert( comparisonOperatorHelper.evaluate("Contains",true, false, "test_test1", "test1",nil) == false )
	assert( comparisonOperatorHelper.evaluate("Contains",false, false, "test_dsdsdsdtest1", "*",nil) )

    assert( comparisonOperatorHelper.evaluate("EqualsAny",false, false, "test1", nil, {"test1"}) )
    assert( comparisonOperatorHelper.evaluate("EqualsAny",false, false, "test1", nil,{"Test1"}) == false )
    assert( comparisonOperatorHelper.evaluate("EqualsAny",false, true, "test1", nil,{"Test1"}) )
    assert( comparisonOperatorHelper.evaluate("EqualsAny",true, false, "test1", nil,{"Test1"}) )
    assert( comparisonOperatorHelper.evaluate("EqualsAny",true, false, "test1", nil,{"test1"}) == false )
    assert( comparisonOperatorHelper.evaluate("EqualsAny",true, true, "test1", nil,{"Test1"}) == false )

    assert( comparisonOperatorHelper.evaluate("ContainsAny",false, false, "test_test1_test", nil,{"test1"}) )
    assert( comparisonOperatorHelper.evaluate("ContainsAny",false, false, "test_test1_test", nil,{"Test1"}) == false )
    assert( comparisonOperatorHelper.evaluate("ContainsAny",false, true, "test_test1_test", nil,{"Test1"}) )
    assert( comparisonOperatorHelper.evaluate("ContainsAny",true, false, "test_test1_test", nil,{"Test1"}) )
    assert( comparisonOperatorHelper.evaluate("ContainsAny",true, true, "test_test1", nil,{"Test1"}) == false )
    assert( comparisonOperatorHelper.evaluate("ContainsAny",true, false, "test_test1", nil,{"test1"}) == false )
    assert( comparisonOperatorHelper.evaluate("ContainsAny",false, false, "test_dsdsdsdtest1", nil,{"*"}) )
end
ComparisonOperatorHelperTest_evaluate()