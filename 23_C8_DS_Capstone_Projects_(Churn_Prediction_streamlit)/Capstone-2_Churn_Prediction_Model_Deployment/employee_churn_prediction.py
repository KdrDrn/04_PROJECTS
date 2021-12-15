import streamlit as st
import pickle
import pandas as pd
from sklearn.preprocessing import MinMaxScaler

st.sidebar.title('Employee Information')

html_temp = """
<div style="background-color:tomato;padding:10px">
<h2 style="color:white;text-align:center;">Employee Churn Prediction</h2>
</div><br><br>"""

st.markdown(html_temp,unsafe_allow_html=True)
selection = st.selectbox("Select Your Model", ["Gradient Boost", "Random Forest", "KNN", "CatBoost"])

if selection =="Gradient Boost":
	st.write("You selected", selection, "model")
	model = pickle.load(open('gradient_boosting_model', 'rb'))
elif selection =="Random Forest":
	st.write("You selected", selection, "model")
	model = pickle.load(open('random_forest_model', 'rb'))
elif selection =="CatBoost":
	st.write("You selected", selection, "model")
	model = pickle.load(open('catboost_model', 'rb'))
else:
	st.write("You selected", selection, "model")
	model = pickle.load(open('kneighbors_model', 'rb'))

satisfaction_level = st.sidebar.slider(label="Satisfaction Level", min_value=0.0, max_value=1.0, step=0.01)
last_evaluation = st.sidebar.slider(label="Last Evaluation", min_value=0.0, max_value=1.0, step=0.01)
number_project = st.sidebar.number_input(label="Number of Projects", min_value=1, max_value=200)
average_monthly_hours = st.sidebar.number_input("Average Monthly Hours", min_value=10, max_value=2000)
time_spend_company = st.sidebar.slider("Time Spend in Company", min_value=0, max_value=30, step=1)
work_accident = st.sidebar.radio("Work Accident", (1, 0))
promotion_last_5years = st.sidebar.radio("Promotion in Last 5 Years", (1, 0))
department = st.sidebar.selectbox("Department", ['RandD', 'accounting', 'hr', 'management', 'marketing', 'product_mng',  'sales', 'support', 'technical', 'IT'])
salary = st.sidebar.selectbox("Salary", ['low', 'medium', 'high'])


coll_dict = {'satisfaction_level':satisfaction_level, 'last_evaluation':last_evaluation, 'number_project':number_project, 'average_montly_hours':average_monthly_hours,\
			'time_spend_company':time_spend_company, 'Work_accident':work_accident, 'promotion_last_5years':promotion_last_5years,\
			'Departments ': department, 'salary':salary}
columns = ['satisfaction_level', 'last_evaluation', 'number_project', 'average_montly_hours', 'time_spend_company',\
            'work_accident', 'promotion_last_5years', 'department_RandD', 'department_accounting', 'department_hr',\
            'department_management', 'department_marketing', 'department_product_mng', 'department_sales',\
            'department_support', 'department_technical', 'salary_low', 'salary_medium']


df_coll = pd.DataFrame.from_dict([coll_dict])
user_inputs = pd.get_dummies(df_coll,drop_first=True).reindex(columns=columns, fill_value=0)


scalerfile = 'scaler.sav'
scaler = pickle.load(open(scalerfile, 'rb'))

scaler.clip = False
user_inputs_transformed = scaler.transform(user_inputs)

prediction = model.predict(user_inputs_transformed)

st.header('Employee Information')
st.table(df_coll)
st.subheader('Click PREDICT if configuration is OK')
if st.button('PREDICT'):
	if prediction[0]==0:
		st.success(prediction[0])
		st.success(f'Employee will STAY :)')
	elif prediction[0]==1:
		st.warning(prediction[0])
		st.warning(f'Employee will LEAVE :(')
