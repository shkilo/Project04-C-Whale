const router = require('express').Router();

const userRouter = require('@routes/user');
const taskRouter = require('@routes/task');
const projectRouter = require('@routes/project');
const labelRouter = require('@routes/label');
const { authenticateUser } = require('@utils/auth');

router.use('/user', userRouter);
router.use('/task', authenticateUser, taskRouter);
router.use('/project', authenticateUser, projectRouter);
router.use('/label', authenticateUser, labelRouter);

module.exports = router;
