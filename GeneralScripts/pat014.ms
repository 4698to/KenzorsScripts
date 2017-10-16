rollout test "Test"
(
pickbutton pck_test ">>Pick An Object" tooltip:"Pick A Scene Object..."
on pck_test picked obj do
if isValidNode obj do pck_test.tooltip = "You picked " + obj.name
)
createDialog test