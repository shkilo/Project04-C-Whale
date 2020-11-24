require('module-alias/register');
const request = require('supertest');
const app = require('@root/app');
const expectedData = require('@test/expected-data');

jest.mock('@models', () => {
  // 추후 global setting 으로 한번에 설정하는 방안 생각
  const connection = require('@test/sequelize-mock');
  return connection;
});

describe('post task', () => {
  it('일반 task 생성', done => {
    // given
    const newTask = {
      title: '할일',
      projectId: expectedData.projects[0].id,
      labelIdList: JSON.stringify(expectedData.labels.map(label => label.id)),
      priorityId: expectedData.priorities[0].id,
      dueDate: '2020-11-28',
      parentId: null,
      alarmId: expectedData.alarms[0].id,
    };

    try {
      request(app)
        .post('/api/task')
        .send(newTask)
        .end((err, res) => {
          if (err) {
            throw err;
          }
          expect(res.status).toBe(201);
          expect(res.body.message).toBe('ok');
          done();
        });
    } catch (err) {
      done(err);
    }
  });

  it('project 없이 생성', done => {
    // given
    const newTask = {
      title: '할일',
      projectId: null,
      labelIdList: JSON.stringify(expectedData.labels.map(label => label.id)),
      priorityId: expectedData.priorities[0].id,
      dueDate: '2020-11-28',
      parentId: null,
      alarmId: expectedData.alarms[0].id,
    };

    try {
      request(app)
        .post('/api/task')
        .send(newTask)
        .end((err, res) => {
          if (err) {
            throw err;
          }
          expect(res.status).toBe(201);
          expect(res.body.message).toBe('ok');
          done();
        });
    } catch (err) {
      done(err);
    }
  });

  it('label 없이 생성', done => {
    // given
    const newTask = {
      title: '할일',
      projectId: expectedData.projects[0].id,
      labelIdList: JSON.stringify([]),
      priorityId: expectedData.priorities[0].id,
      dueDate: '2020-11-28',
      parentId: null,
      alarmId: expectedData.alarms[0].id,
    };

    try {
      request(app)
        .post('/api/task')
        .send(newTask)
        .end((err, res) => {
          if (err) {
            throw err;
          }
          expect(res.status).toBe(201);
          expect(res.body.message).toBe('ok');
          done();
        });
    } catch (err) {
      done(err);
    }
  });

  it('priority 없이 생성', done => {
    // given
    const newTask = {
      title: '할일',
      projectId: expectedData.projects[0].id,
      labelIdList: JSON.stringify([]),
      priorityId: JSON.stringify([]),
      dueDate: '2020-11-28',
      parentId: null,
      alarmId: expectedData.alarms[0].id,
    };

    try {
      request(app)
        .post('/api/task')
        .send(newTask)
        .end((err, res) => {
          if (err) {
            throw err;
          }
          expect(res.status).toBe(201);
          expect(res.body.message).toBe('ok');
          done();
        });
    } catch (err) {
      done(err);
    }
  });

  it('alarm 없이 생성', done => {
    // given
    const newTask = {
      title: '할일',
      projectId: expectedData.projects[0].id,
      labelIdList: JSON.stringify([]),
      priorityId: JSON.stringify([]),
      dueDate: '2020-11-28',
      parentId: null,
      alarmId: null,
    };

    try {
      request(app)
        .post('/api/task')
        .send(newTask)
        .end((err, res) => {
          if (err) {
            throw err;
          }
          expect(res.status).toBe(201);
          expect(res.body.message).toBe('ok');
          done();
        });
    } catch (err) {
      done(err);
    }
  });

  it('alarm 없이 생성', done => {
    // given
    const newTask = {
      title: '할일',
      projectId: expectedData.projects[0].id,
      labelIdList: JSON.stringify([]),
      priorityId: JSON.stringify([]),
      dueDate: '2020-11-28',
      parentId: null,
      alarmId: null,
    };

    try {
      request(app)
        .post('/api/task')
        .send(newTask)
        .end((err, res) => {
          if (err) {
            throw err;
          }
          expect(res.status).toBe(201);
          expect(res.body.message).toBe('ok');
          done();
        });
    } catch (err) {
      done(err);
    }
  });

  it('하위 task 생성', done => {
    // given
    const newTask = {
      title: '할일',
      projectId: expectedData.projects[0].id,
      labelIdList: JSON.stringify([]),
      priorityId: JSON.stringify([]),
      dueDate: '2020-11-28',
      parentId: expectedData.tasks[0].id,
      alarmId: expectedData.alarms[0].id,
    };

    try {
      request(app)
        .post('/api/task')
        .send(newTask)
        .end((err, res) => {
          if (err) {
            throw err;
          }
          expect(res.status).toBe(201);
          expect(res.body.message).toBe('ok');
          done();
        });
    } catch (err) {
      done(err);
    }
  });
});
